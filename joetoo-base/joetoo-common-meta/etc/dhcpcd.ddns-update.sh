#!/bin/bash
#
# This script performs a secure DDNS update using nsupdate
#
PN=$(basename $0)

#-----[ user configured variables ]---------------------------------------------------
user="joe"
ddns_server="elrond"
domain="brendler"

# tp-do: transition to pairwise-unique (or client-qunique keys) for greater security
# (with a shared key [status quo] compromise of any client enables actor to impersonate
#  any remote hostname in spoofed dns updates - sending false ip addr for the impersonated host)
ssh_key_id="id_ddns_update"

debugging_log="/tmp/dhcpcd.ddns-update.debug.log"
LOG_FACILITY="local5"

#-----[ derived variables ]----------------------------------------------------------
# The key is owned by '${user}' and used via 'sudo -u ${user}'
SSH_KEY_PATH="/home/${user}/.ssh/${ssh_key_id}"
DDNS_SSH_TARGET="${user}@${ddns_server}.${domain}"
# The Fully Qualified Domain Name
FQDN="$(hostname).${domain}"

# Get parameters passed as arguments by hook script
#    /lib/dhcpcd/dhcpcd-hooks/99-ddns-update, which must be executable
#    for this script to get hooked if these events fire
REASON="$1"
INTERFACE="$2"
OLD_ADDR="$3"
NEW_ADDR="$4"

#-----[ functions ]-----------------------------------------------------------
timestamp() {
    echo "$(date '+%Y-%m-%d_%H:%M:%S')"
}

#-----[ main script ]---------------------------------------------------------

# Log the Initial State
{
    echo "-----[ ${PN} started at $(timestamp) ]----------------"
    echo "    REASON: ....: [$REASON]"
    echo "    INTERFACE ..: [$INTERFACE]"
    echo "    OLD_ADDR ...: [$OLD_ADDR]"
    echo "    NEW_ADDR ...: [$NEW_ADDR]"
} >> "$debugging_log"

msg="[$(timestamp)] DEBUG: DDNS_UPDATE Script Invoked. REASON: [$REASON] INTERFACE: [$INTERFACE]"
logger -p "${LOG_FACILITY}.debug" -t "${PN}" "${msg}"
msg="[$(timestamp)] DEBUG: OLD_ADDR: [$OLD_ADDR] NEW_ADDR: [$NEW_ADDR]"
logger -p "${LOG_FACILITY}.debug" -t "${PN}" "${msg}"

# Extract the ULA IPv6 address from the passed new and old address variables (removes /64 netmask)
# These variables are supplied by dhcpcd hooks when an IPv6 address is available,
# and this assignment SHOULD pass valid ULA addresses to the input validateion below
NEW_IPV6_ADDRESS=$(echo "$NEW_ADDR" | cut -d/ -f1)
OLD_IPV6_ADDRESS=$(echo "$OLD_ADDR" | cut -d/ -f1)

# Input validation and ACTION_MSG assignment
#
# check the reason we got hooked before we know whether to
#    validate a new/renewed address or the old one we are going to delete
if echo "$REASON" | grep -E 'IPV6L_RENEW|IPV6_RENEW|IPV6L_UP|IPV6_UP|BOUND|CARRIEER|ROUTERADVERT' >/dev/null; then
    # this is a renewal or addition of the ip address we assigned above
    ACTION_MSG="Updated"
    # Try to use the address passed by dhcpcd (most relevant if populated)
    ACTION_IPV6_ADDRESS="${NEW_IPV6_ADDRESS}"
    if [ -z "$ACTION_IPV6_ADDRESS" ]; then
        msg="[$(timestamp)] WARNING: \$NEW_ADDR was empty for [$REASON]. Falling back to manual lookup (after delay) ..." >> "$debugging_log"
        # Temporary Delay for Slow SLAAC
    if echo "$REASON" | grep -E 'BOUND|IPV6L_UP|IPV6_UP' >/dev/null ; then
            # Delay for 1 minute (60 seconds) to ensure the ULA is attached
      �msg="[$(timestamp)] INFO: Delaying 60s for slow SLAAC/RA on [$REASON] event..." >> "$debugging_log"
            sleep 60
        fi  # (delay)
        if [ -z "$INTERFACE" ] ; then
            msg="FAILURE: \$INTERFACE was empty (reliable lookup not possible)..." >> "$debugging_log"
            exit 0
        else
            # The exact robust command provided by the user, scoped to the relevant interface
            ACTION_IPV6_ADDRESS=$(ip -6 addr show dev "$INTERFACE" | \
                grep -E 'inet6[[:space:]]+fd62' | \
                awk '{print $2}' | \
                cut -d/ -f1 | \
                head -n 1)
        fi # interface
    fi # address
elif echo "$REASON" | grep -E 'IPV6L_EXPIRE|IPV6_EXPIRE|DECONFIG|STOPPED' >/dev/null; then
    # this is a removal of the name - address from the hosts file, for this reason
    ACTION_MSG="Deleted"
    # For deletion, we MUST rely on the OLD address passed (cannot look up removed address)
    ACTION_IPV6_ADDRESS="${OLD_IPV6_ADDRESS}"
else
    # this shouldn't happen (hook script logic)
    msg="[$(timestamp)] SKIPPED:: update for reason: [$REASON] not implented."
    logger -p "${LOG_FACILITY}.info" -t "${PN}" "${msg}"
    echo "${msg}" >> "${debugging_log}"
    exit 0
fi # reason

# now that we know which address matters, validate it
if [ -z "$ACTION_IPV6_ADDRESS" ]; then
    # the variable is an "empty" string
    msg="[$(timestamp)] INVALID: Empty address provided by hook script for reason: [$REASON]"
    logger -p "${LOG_FACILITY}.err" -t "${PN}" "${msg}"
    echo "${msg}" >> "${debugging_log}"
    exit 0
elif [[ ! "$ACTION_IPV6_ADDRESS" =~ ^[fF][dD][0-9a-fA-F:]*$ ]] ; then
    # this string does not match the format expected for a valid ULA address
    msg="[$(timestamp)] INVALID: address provided by hook script for reason: [$REASON] is not a valid ULA address"
    logger -p "${LOG_FACILITY}.err" -t "${PN}" "${msg}"
    echo "${msg}" >> "${debugging_log}"
    exit 0
else
    # looks good; just log progress
    msg="[$(timestamp)] UPDATE READY: action: [$ACTION_MSG] address: [$ACTION_IPV6_ADDRESS]"
    logger -p "${LOG_FACILITY}.err" -t "${PN}" "${msg}"
    echo "${msg}" >> "${debugging_log}"

# Final command arguments: ADDRESS, FQDN, INTERFACE, and timestamp
# (INTERFACE to be used in NS hosts file '#' comment field
#  in oder to distinguish between multiple addresses for a fqdn
#  when that host has multiple interfaces with ipv6 addresses)
# (timestamp in same comment field for visibly obvious confirmation)
COMMAND_ARGS="${ACTION_IPV6_ADDRESS} ${FQDN} ${INTERFACE} $(timestamp)"

msg="[$(timestamp)] Executing SSH as ${user} with args: [$COMMAND_ARGS]..."
logger -p "${LOG_FACILITY}.info" -t "${PN}" "${msg}"
echo "${msg}" >> "$debugging_log"

# Execute the secure SSH command as ${user}
# CRITICAL: We pass the FQDN and IPV6_ADDRESS as a single, quoted argument string
SSH_OUTPUT=$( \
    /usr/bin/sudo -u "${user}" /usr/bin/ssh \
    -i "$SSH_KEY_PATH" \
    -o StrictHostKeyChecking=yes \
    -o BatchMode=yes \
    "$DDNS_SSH_TARGET" \
    "${COMMAND_ARGS}" 2>&1 \
)
EXIT_CODE=$?
# Log the action taken
{
    echo "SSH Exit Code: $SSH_EXIT_CODE"
    echo "SSH Output (Stdout/Stderr):"
    if [ $EXIT_CODE -eq 0 ]; then
        msg="SSH exit code: [$EXIT_CODE] RESULT: SUCCESS. ${ACTION_MSG} AAAA record for ${FQDN} on $INTERFACE."
        logger -p "${LOG_FACILITY}.info" -t "${PN}" "${msg}"
        echo "${msg}"
    else
        msg="[$(timestamp)] SSH exit code: [$EXIT_CODE] RESULT: FAILED. failed to update AAAA record for ${FQDN}."
        logger -p "${LOG_FACILITY}.err" -t "${PN}" "${msg}"
        echo "${msg}"
    fi
    echo "-----[ ${PN} fnished at $(timestamp) ]----------------"
} >> "${debugging_log}"
exit 0
