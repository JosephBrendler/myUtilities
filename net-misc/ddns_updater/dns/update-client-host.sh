#!/bin/bash
#
# server side of client ddns update script executed by ssh command under authorized_keys
#   constraining user key id to just this one command
#

#-----[ variables ]----------------------------------------------------------------

if [ $# -eq 4 ]; then
    # legacy mode: client dhcpcd hooked /etc/dhcpcd.ddns_update.sh mode (does not support delete event)
    EVENT="add"
    IPV6_ADDR="$1"
    FQDN="$2"
    INTERFACE="$3"
    TIMESTAMP="$4"
elif [ $# -eq 5 ]; then
    # new mode: client ddns-watcher service with ddns_watcher daemon and /usr/sbin/ddns-update script
    IPV6_ADDR="$1"
    FQDN="$2"
    INTERFACE="$3"
    TIMESTAMP="$4"
    EVENT="$5"
else
    printf '%s\n' "Invalid argument count"
    exit 1
fi

user="joe"

W0="[[:space:]]*" # regex match for zero or more whitespaces
W1="[[:space:]]+" # regex match for one or more whitespaces
P0="[[:print:]]*" # regex match for zero or more printable characters (incl. whitespace)
P1="[[:print:]]+" # regex match for one or more printable characters (incl. whitespace)
G0="[[:graph:]]*" # regex match for zero or more printable characters (excl. whitespace)
G1="[[:graph:]]+" # regex match for one or more printable characters (excl. whitespace)

HOSTS_FILE="/etc/hosts.d/30_ddns_clients"
TEMP_FILE=$(mktemp)

debug_logfile=/tmp/ddns_update-client-host.debug.log

LOCK_DIR="/run/lock/ddns_updater"
# Ensure the lock file directory is created, owned by root, and persistent across reboots
/bin/mkdir -p "$LOCK_DIR"

# Ensure the lock file exists and is owned by user
# Note: If $LOCK_FILE already exists, this does nothing but update the timestamp.
# I might want to change ownership if other users/services need to acquire the lock.
#LOCK_FILE="${LOCK_DIR}/${FQDN}-${INTERFACE}.lock"
# 20260306 - changed from per-interface to per-client lock to prevent client-initiated race between
#   its own multiple interface updates
# 20260306 #2 - changed from per-client to one single hosts file lock to prevent multi-client races
#LOCK_FILE="${LOCK_DIR}/${FQDN}.lock"
# use "basename" of hosts_file for the name of lock
LOCK_FILE="${LOCK_DIR}/${HOSTS_FILE##*/}.lock"

/usr/bin/touch "$LOCK_FILE"
/bin/chown "${user}" "$LOCK_FILE"

# Acquire exclusive lock (non-sudo) with fd 200 b/c it is well above range used for normal shell ops
exec 200>"$LOCK_FILE"
# originally used flock -x 200 (exclusive lock; only one process can hold it)
# but the default behavior of processes encountering this is "blocking" (to freeze and wait)
# "like accepting a phone call, but replying 'sorry - too busy right now'"
####/usr/bin/flock -x 200 || { printf '%s\n' "Error: Updater is busy for ${FQDN}. Exiting." | tee -a "$debug_logfile" >&2; exit 1; }
# I would rather have clients approach this like,
#   "If the server is busy just skip this update and try again later"
# so - so they should gracefully decline to act, instead, this is enabled by using
# a non-blocking lock, and then rejecting the new process
if ! /usr/bin/flock -n 200; then
    msg="[$(timestamp)] NOTICE: Updater is busy for ${FQDN}. Exiting non-blocking."
    printf '%s\n' "$msg" | tee -a "$debug_logfile" >&2
    exit 0 # Exit successfully (code 0) to prevent the client from logging an error
fi

#-----[ functions ]----------------------------------------------------------------
timestamp () { printf '%s\n' "$(date +'%Y%m%d-%H:%M:%S')" ; }

#-----[ main script ]----------------------------------------------------------------
# initiate log entry
{
printf '%s\n' "IPV6_ADDR: $IPV6_ADDR"
printf '%s\n' "FQDN: $FQDN"
printf '%s\n' "INTERFACE: $INTERFACE"
printf '%s\n' "TIMESTAMP: $TIMESTAMP"
printf '%s\n' "EVENT: $EVENT"
printf '%s\n' "user: $user"
printf '%s\n' "HOSTS_FILE: $HOSTS_FILE"
printf '%s\n' "TEMP_FILE: $TEMP_FILE"
printf '%s\n' "LOCK_DIR: $LOCK_DIR"
printf '%s\n' "LOCK_FILE: $LOCK_FILE"
} | tee -a "$debug_logfile" >&2

# if this is a delete action, process it and exit early (otherwise add)
if [ "$EVENT" = "del" ]; then
    # remove lines that semantically match <something-ie-address><fqdn><space># followed by
    #   <something-and-or-space>interface followed by either <space><anything>Eeol> OR
    #       interface followed by <eol> -
    #   i.e. match/delete for interface=eth1: "<addr> <fqdn> #oops eth1 whatever"
    #   but do not match "<addr> <fqdn> #oops eth11"

    msg="[$(timestamp)] (debug) Delete [$EVENT]. dumping original HOSTS_FILE"
    printf '%s\n' "$msg" | tee -a "$debug_logfile" >&2
    nl -ba "$HOSTS_FILE" | tee -a "$debug_logfile" >&2

    grep -v "^${W0}${G1}${W1}${FQDN}${W1}#${P0}${INTERFACE}${W1}${P0}$" "$HOSTS_FILE" \
        | grep -v "^${W0}${G1}${W1}${FQDN}${W1}#${P0}${INTERFACE}$" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$HOSTS_FILE"

    msg="[$(timestamp)] (debug) Delete [$EVENT]. dumping updated HOSTS_FILE"
    printf '%s\n' "$msg" | tee -a "$debug_logfile" >&2
    nl -ba "$HOSTS_FILE" | tee -a "$debug_logfile" >&2

    /etc/init.d/dnsmasq reload
    exit 0
fi

# Check for valid input
if [ -z "$FQDN" ] || [ -z "$IPV6_ADDR" ]; then
    printf '%s\n' "Error: Missing FQDN or IPv6 Address. Usage: FQDN IPV6_ADDR"
    exit 1
fi

#msg="[$(timestamp)] (debug) Add [$EVENT]. dumping updated HOSTS_FILE"
#printf '%s\n' "$msg" | tee -a "$debug_logfile" >&2
#nl -ba "$HOSTS_FILE" | tee -a "$debug_logfile" >&2

# Note: All file access operations must be run with sudo for read/write access.
# (depends on user running the script to have NOPASSWD access to the script
#  which is granted in /etc/sudoers.d/99-ddns-update

# Read all existing entries *EXCEPT* the line corresponding to the FQDN and INTERFACE
#    into the temporary file. This handles multi-homing by removing ONLY the old IP for this FQDN/Interface
# Note: regex checks the entire line for a properly formatted hosts file entry, in the form
#fd00:0000:0062:0:8536:c72f:2be6:46c0    gmki91.brendler # wlan0 (absent this comment's leading #)
# ^${W0}${G1}${W1}${FQDN} - BOL, any text (incl at least some non-whitespace [ip_address]), then $FQDN
# ${W1}#${P1}${INTERFACE} - at least one space, '#', any addl comment prefix, $INTERFACE
# ${P0}$" - any printable comment suffix, EOL
# zero or more printable characters (incl. whitespace) (incl any address) followed by $FQDN - then
# followed by one or more whitespaces and one or more printable characters (any comment prefix) - then
# $INTERFACE followed by zero or more printable characters, to the end of the line (any addl comment text)
#/bin/grep -E -v "^${W0}${G1}${W1}${FQDN}${W1}#${P1}${INTERFACE}${P0}$" "$HOSTS_FILE" | \
/bin/grep -E -v "^${W0}${G1}${W1}${FQDN}${W1}#${P0}${INTERFACE}${P0}$" "$HOSTS_FILE" > "$TEMP_FILE"

#printf '%s\n' "DEBUG: FQDN=[$FQDN] INTERFACE=[$INTERFACE]" | tee -a "$debug_logfile" >&2
#printf '%s\n' "DEBUG: Removal regex: [^${W0}${G1}${W1}${FQDN}${W1}#${P0}${INTERFACE}${P0}$]" | tee -a "$debug_logfile" >&2

# dump the original hosts file and new temp file using nl (numbered lines)
#  -ba : body-numbering with style "a" (number all lines) > redirect to stderr
#printf '%s\n' "DEBUG: Original hosts file:" | tee -a "$debug_logfile" >&2
#nl -ba "$HOSTS_FILE" | tee -a "$debug_logfile" >&2

#printf '%s\n' "DEBUG: Temp file after grep removal:" | tee -a "$debug_logfile" >&2
#nl -ba "$TEMP_FILE" | tee -a "$debug_logfile" >&2

# Append the new entry to THE TEMP_FILE in the standard IP FQDN # INTERFACE timestamp format
printf "%-38s %-20s # %-10s %s\n" "$IPV6_ADDR" "$FQDN" "$INTERFACE" "$TIMESTAMP" >> "$TEMP_FILE"

#printf '%s\n' "DEBUG: Temp file after append:" | tee -a "$debug_logfile" >&2
#nl -ba "$TEMP_FILE" | tee -a "$debug_logfile" >&2

# Sort the final content based on FQDN (field 2) and overwrite the privileged file.
#    sort syntax primary key -k<field1>.<char40>,<field2>{implied .<endoffield2>
#    which is a "40-character offset to ignor and start sorting on characters after
#    the confusing field 1 (ipv6 addr) primary key -k2, should have but did not work
#    secondary key -k4,4 sorts on all of field 4 (interface, since # is field 3)
#    together: group by fqdn in alpha order, and within those groups sort by interface
#    LC_COLLATE helps sort understand cap Z does not precede lowcase a in the alphablet
LC_COLLATE="en_US.UTF-8" /usr/bin/sort -k1.40,2 -k4,4 "$TEMP_FILE" | \
    /usr/bin/tee "$HOSTS_FILE" > /dev/null

# make sure the hosts file will be readable by dnsmasq
chmod 644 "$HOSTS_FILE" ; result=$?
if [ "$result" -eq 0 ] ; then
    printf '%s\n' "successfully set 644 permissions on $HOSTS_FILE" | tee -a "$debug_logfile" >&2
else
    printf '%s\n' "failed to set 644 permissions on $HOSTS_FILE" | tee -a "$debug_logfile" >&2
fi

printf '%s\n' "DEBUG: new HOSTS file after final sort:" | tee -a "$debug_logfile" >&2
nl -ba "$TEMP_FILE" | tee -a "$debug_logfile" >&2

# Clean up the temporary file
rm -f "$TEMP_FILE"

# Trigger dnsmasq to reread the hosts file
/etc/init.d/dnsmasq reload
printf '%s\n' "SUCCESS: Updated ${FQDN} to ${IPV6_ADDR} and reloaded dnsmasq."

# Note: lock file is automatically released when script completes

