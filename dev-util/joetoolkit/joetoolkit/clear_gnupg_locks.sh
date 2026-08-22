#!/bin/bash
# shellcheck source=/usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo

checkroot

PN=${0##*/}
if [ -f /etc/joetoolkit/BUILD ]; then
    . /etc/joetoolkit/BUILD
else
    BUILD="0.0.0"
fi

#-----[ variables ]-------------------------------------------------------------
signing_keyring_dir="/root/.gnupg"
# form a regex equivalent, preserving the . in .gnupg
signing_keyring_re="${signing_keyring_dir//./\\.}"

signing_pubkey_dir="${signing_keyring_dir%/}/public-keys.d"
signing_keydb="${signing_pubkey_dir%/}/pubring.db"
signing_lock="${signing_pubkey_dir%/}/pubring.db.lock"

signing_key_email="joseph.brendler@gmail.com"

verification_keyring_dir="/etc/portage/gnupg"

# to read your signing keygrip, do e.g. -
# gpg --homedir="${signing_keyring_dir}" --with-keygrip -K "${signing_key_email}"
# (note: pick the "sec" keygrip, not the "ssb")
signing_keygrip="661F32EE3F3EC59ABC93730764EB3948A3A034E1"

declare -a sandbox_paths=()

#-----[ main script ]-----------------------------------------------------------
separator "$(hostname)" "${PN}-${BUILD}"

# discover configured SANDBOX_WRITE paths
j_msg "-${notice}" -p -n "Reading configured SANDBOX_WRITE paths"
readarray -d: -t sandbox_paths < <(portageq envvar SANDBOX_WRITE)
handle_result $? "ingested [${#sandbox_paths[@]}] paths" "" "$notice"

for path in "${sandbox_paths[@]}"; do
    [ -n "$path" ] && j_msg "-${info}" -m "  SANDBOX_WRITE: $path"
done

# show starting GnuPG state
j_msg "-${notice}" -p "GnuPG processes before cleanup:"
#   pgrep --help | grep -E ' \-a| \-f' 2>/dev/null
#    -a, --list-full -- list PID and full command line
#    -f, --full      -- use full command line to match
if pgrep -af 'gpg|gpg-agent|keyboxd|scdaemon|dirmngr'; then
    :
else
    j_msg "-${notice}" -p "  none"
fi

# first ask gnupg to cleanly terminate all components for both keyrings
for dir in "$signing_keyring_dir" "$verification_keyring_dir"; do
    j_msg "-${notice}" -p -n "Running gpgconf --homedir=$dir --kill all"
    gpgconf --homedir="$dir" --kill all 2>/dev/null
    right_status $? "$notice"
    milli_sleep 250
done

# stop stray signing-keyring daemons
# a failed portage signing operation can leave a second keyboxd trying to use
# /root/.gnupg/public-keys.d/pubring.db but listening on a separate socket
# (e.g.)/run/user/<UID>/d.<hash>/S.keyboxd
# Such a keyboxd might NOT have pubring.db open, so checking fuser
# against the database file alone is not sufficient
#

j_msg "-${notice}" -p -n "Terminating keyboxd daemons for ${signing_keyring_dir}"
# pkill --help | grep -E ' \-f| -<sig>' 2>/dev/null
#   -<sig>      -- signal to send (either number or name)
#   -f, --full  -- use full command line to match
#   -x, --exact -- match exactly with the command name
#   returns 0 if at least one matching process was successfully signaled
#   returns 1 if no process matched the selection criteria
pkill -TERM -f "^keyboxd --homedir ${signing_keyring_re} --daemon$" 2>/dev/null
rc=$?
[ $rc -eq 0 ] || [ $rc -eq 1 ]
right_status $? "$notice"
milli_sleep 500

j_msg "-${notice}" -p -n "Terminating gpg-agent daemons for ${signing_keyring_dir}"
pkill -TERM -f "^gpg-agent --homedir ${signing_keyring_re} .*" 2>/dev/null
rc=$?
[ $rc -eq 0 ] || [ $rc -eq 1 ]
right_status $? "$notice"
milli_sleep 500

# scdaemon is normally a child/worker of root's gpg-agent; once the
# signing agent is gone, any remaining scdaemon is stale for this cleanup.
if pgrep -x scdaemon &>/dev/null; then
    j_msg "-${notice}" -p -n "Terminating remaining scdaemon process(es)"
    pkill -TERM -x scdaemon 2>/dev/null
    right_status $? "$notice"
    milli_sleep 250
else
    j_msg "-${notice}" -p "No scdaemon processes running"
fi


# escalate stubborn signing-keyring daemons
if pgrep -f "^keyboxd --homedir ${signing_keyring_re} --daemon$" &>/dev/null; then
    j_msg "-${warn}" -p -n "Force-killing remaining keyboxd daemon(s)"
    pkill -KILL -f "^keyboxd --homedir ${signing_keyring_re} --daemon$" 2>/dev/null
    right_status $? "$warn"
    milli_sleep 250
else
    j_msg "-${notice}" -p "No signing-keyring keyboxd processes remain"
fi

if pgrep -f "^gpg-agent --homedir ${signing_keyring_re} " &>/dev/null; then
    j_msg "-${warn}" -p -n "Force-killing remaining gpg-agent daemon(s)"
    pkill -KILL -f "^gpg-agent --homedir ${signing_keyring_re} " 2>/dev/null
    right_status $? "$warn"
    milli_sleep 250
else
    j_msg "-${notice}" -p "No signing-keyring gpg-agent processes remain"
fi

# verify and terminate any process still holding pubring.db
# fuser -h 2>&1 | grep -E ' \-k| \-v| \-SIGNAL' 2>/dev/null
#   -k,--kill    -- kill processes accessing the named file
#   -SIGNAL      -- send this signal instead of SIGKILL
#   -v,--verbose -- verbose output
if [ -f "$signing_keydb" ]; then
    if fuser "$signing_keydb" &>/dev/null; then
        j_msg "-${warn}" -p "Signing database still has live holder(s):"
        fuser -v "$signing_keydb"

        j_msg "-${warn}" -p -n "Terminating holder(s) of ${signing_keydb}"
        fuser -k "$signing_keydb" 2>/dev/null
        right_status $? "$warn"
        milli_sleep 500
    else
        j_msg "-${notice}" -p "Signing database has no live holders"
    fi

    if fuser "$signing_keydb" &>/dev/null; then
        j_msg "-${warn}" -p -n "Force-killing remaining holder(s) of ${signing_keydb}"
        fuser -k -9 "$signing_keydb" 2>/dev/null
        right_status $? "$warn"
        milli_sleep 250
    fi

    j_msg "-${notice}" -p -n "Verifying ${signing_keydb} is no longer in use"
    ! fuser "$signing_keydb" &>/dev/null
    handle_result $? \
        "database has no live holder" \
        "database is still in use; refusing to remove lock state" \
        "$notice" || die "failed to release signing database"
else
    j_msg "-${warn}" -p "Signing database [$signing_keydb] does not exist"
fi

# verify no signing-keyring keyboxd remains before removing lock/socket files
j_msg "-${notice}" -p -n "Verifying no signing-keyring keyboxd daemon remains"
! pgrep -f "^keyboxd --homedir ${signing_keyring_re} --daemon$" &>/dev/null
handle_result $? \
    "no keyboxd daemon remains" \
    "a signing-keyring keyboxd daemon is still running" \
    "$notice" || die "keyboxd cleanup incomplete"

# remove stale signing-keyring locks and local socket files
j_msg "-${notice}" -p -n "Removing stale ${signing_lock}"
rm -f "$signing_lock"
right_status $? "$notice"

j_msg "-${notice}" -p -n "Removing numbered GnuPG lock files"
find "$signing_pubkey_dir" -maxdepth 1 -type f -name '.#lk*' -delete
right_status $? "$notice"

j_msg "-${notice}" -p -n "Removing stale GnuPG home socket files"
rm -f "${signing_keyring_dir%/}"/S.*
right_status $? "$notice"

# clean runtime GnuPG socket directories discovered from SANDBOX_WRITE
# Caution: do NOT recursively clear every SANDBOX_WRITE path
#   Some entries are broad directories such as /run/user/0 or /root/.gnupg
#   Only remove known GnuPG runtime subdirectories
for path in "${sandbox_paths[@]}"; do
    [ -n "$path" ] || continue

    case "$path" in
        /run/user/*|/dev/shm/user/*)
            if [ -e "${path%/}/gnupg" ]; then
                j_msg "-${notice}" -p -n "Removing stale runtime state ${path%/}/gnupg"
                rm -rf -- "${path%/}/gnupg"
                right_status $? "$notice"
            fi
            ;;
    esac
done

# also clean known fallback locations in case an older machine's
# SANDBOX_WRITE does not yet contain the current complete set
for keyring_dir in /run/user/0/gnupg /run/user/0-runtime/gnupg /dev/shm/user/0-runtime/gnupg; do
    if [ -e "$keyring_dir" ]; then
        j_msg "-${notice}" -p -n "Removing stale fallback runtime state $keyring_dir"
        rm -rf -- "$keyring_dir"
        right_status $? "$notice"
    fi
done

# report any remaining lock state
j_msg "-${notice}" -p "Checking for remaining signing-keyring lock files ..."
# poplate array with paths to .#lk* and *.lock files
find_args=("$signing_keyring_dir" -maxdepth 3 -type f)
name_args=(-name '.#lk*' -o -name '*.lock')
readarray -t remaining_locks < <( find "${find_args[@]}" \( "${name_args[@]}" \) -print )

if [ ${#remaining_locks[@]} -gt 0 ]; then
    j_msg "-${warn}" -p "Remaining lock files:"
    printf '    %s\n' "${remaining_locks[@]}"
else
    j_msg "-${notice}" -p "No signing-keyring lock files remain"
fi

# verify keyring remains readable
# (this will normally restart a clean keyboxd/agent context)
j_msg "-${notice}" -p -n "Verifying signing keyring is readable"
gpg --homedir "$signing_keyring_dir" --list-keys "$signing_key_email" &>/dev/null
handle_result $? "readable" "unreadable" "$notice" || die "signing keyring verification failed"

# clean up portage temporary workspace
j_msg "-${notice}" -p -n "Reading PORTAGE_TMPDIR"
PORTAGE_TMPDIR="$(portageq envvar PORTAGE_TMPDIR)"
handle_result $? "${PORTAGE_TMPDIR}" "failed" "$notice"

if [ -n "$PORTAGE_TMPDIR" ]; then
    # form and normalize temp_dir
    temp_dir="${PORTAGE_TMPDIR%/}/portage/"
    j_msg "-${notice}" -p -n "Cleaning Portage temporary workspace ${temp_dir}"
    # remove three patterns "*" = any string not starting with '.'
    # ".[!.]*" = literal . char followed by non-'.' followed by zero+ anything
    # "..?*" = two litterl . chars followed by one arbitrary char, followed by zero+ anything
    rm -rf -- "${temp_dir}"* "${temp_dir}".[!.]* "${temp_dir}"..?* 2>/dev/null
    handle_result $? '' '' "$notice"
else
    handle_result 1 "" "invalid PORTAGE_TMPDIR [$PORTAGE_TMPDIR]" "$notice"
fi

# restart clean signing agent and preset signing-key passphrase
j_msg "-${notice}" -p -n "Re-starting gpg-agent"
gpg-connect-agent --homedir "$signing_keyring_dir" reloadagent /bye &>/dev/null
right_status $? "$notice"

j_msg "-${notice}" -p "Presetting cached signing-key passphrase ..."
pass_phrase="$(ask_pass "    Enter signing keyring passphrase: ")"

j_msg "-${notice}" -p -n "Presetting passphrase for keygrip ${signing_keygrip}"
printf '%s\n' "$pass_phrase" |
    /usr/libexec/gpg-preset-passphrase \
        --homedir "$signing_keyring_dir" \
        --preset "$signing_keygrip"
handle_result $? "passphrase cached" "failed" "$notice"
unset pass_phrase

# final report
j_msg "-${notice}" -p "GnuPG processes after recovery:"
if pgrep -af 'gpg|gpg-agent|keyboxd|scdaemon|dirmngr'; then
    :
else
    j_msg "-${notice}" -p "  none"
fi

j_msg "-${notice}" -m "Done"
