#!/bin/bash
# shellcheck source=/usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo

checkroot

PN=${0##*/}
if [ -f /etc/joetoolkit/BUILD ]; then . /etc/joetoolkit/BUILD; else BUILD="0.0.0"; fi

signing_keyring_dir="/root/.gnupg"
signing_key_email="joseph.brendler@gmail.com"

verification_keyring_dir="/etc/portage/gnupg"

# to read your signing keygrip, do e.g. -
# gpg --homedir="${signing_keyring_dir}" --with-keygrip -K "${signing_key_email}"
# (note: pick the "sec" keygrip, not the "ssb"
signing_keygrip="661F32EE3F3EC59ABC93730764EB3948A3A034E1"


signing_pubkey_dir="${signing_keyring_dir%/}/public-keys.d"
signing_lock="${signing_pubkey_dir%/}/pubring.db.lock"

separator "$(hostname)" "${PN}-${BUILD}"

# start with the proper tools to properly terminate all active GnuPG components
for x in "$signing_keyring_dir" "$verification_keyring_dir"' do
  j_msg "-${notice}" -p "Running gpgconf --homedir=\"$x\" --kill all ..."
  gpgconf --homedir="${x}" --kill all
  handle_result $? '' '' "$notice"
done

# the lockout this script corrects is usually caused by stale keyboxd, gpg, or gpg-agent processes
# holding a lock on the signing keys ...
# if there are gpg, keyboxd, scdaemon, dirmngr, or gpg-agent processes, kill them
# (keyboxd and gpg-agent are transient daemons managed completely on-demand by GnuPG,
#  it is safe to forcefully terminate them when no cryptographic tasks are actively processing;
#  they will cleanly respawn on next package build)
# (-9 causes this to use SIGKILL - more forcefull vs SIGTERM w/o -9)
# use -x to be exact about name
# gpg is the front end (kill first), gpg-agent is the master back end (kill last)
# scdaemon is a child-worker, dirmngr is a network-worker, keyboxd is database manager (for gpg-agent)
for x in gpg scdaemon dirmngr keyboxd gpg-agent ; do
  if pgrep -x "$x" &>/dev/null; then
    j_msg "-${notice}" -p -n "running killall $x"
    killall -9 "$x" 2>/dev/null
    right_status $? "$notice"
  else
    j_msg "-${notice}" -p "no [$x] processes running"
  fi
  milli_sleep 150
done

# if the signing keyring is locked, remove the lock(s)
if [ -f "${signing_lock}" ] ; then
    j_msg "-${notice}" -p "Signing keyring is ${BRon}locked${Boff}"
    j_msg "-${notice}" -m -n "Unlocking"
    rm -f "${signing_lock}" &>/dev/null
    handle_result $? "" "" "$notice" || die "failed to unlock signing keyring"
    j_msg "-${notice}" -m -n "removing individual numbered lock files"
    find "${signing_pubkey_dir%/}" -name '.#lk*' -delete &>/dev/null
    handle_result $? "" "" "$notice" || die "failed to remove numbered lock files"
else
    j_msg "-${notice}" -p "Signing keyring is ${BGon}not locked${Boff}"
fi

# verify lock(s) cleared
j_msg "-${notice}" -p -n "Verifying signing key is unlocked"
gpg --homedir "${signing_keyring_dir}" --list-keys > /dev/null
right_status $? "$notice"

# clean out Portage's temporary workspace
j_msg "-${notice}" -p -n "cleaning out portage temp workspace"
PORTAGE_TMPDIR=$(source /etc/portage/make.conf; printf '%s\n' "$PORTAGE_TMPDIR")
rm -rf "${PORTAGE_TMPDIR%/}/portage/"* 2>/dev/null
right_status $? "$notice"

# now unlock the keyring for upcoming emerge operations (joetoo_script_header ask_pass)
j_msg "-${notice}" -p -n "Re-starting gpg-agent"
gpg-connect-agent reloadagent /bye &>/dev/null
right_status $? "$notice"

j_msg "-${notice}" -p "Presetting cached passphrase ..."
pass_phrase="$(ask_pass "    Enter signing keyring passphrase: ")"
printf '%s\n' "$pass_phrase" | /usr/libexec/gpg-preset-passphrase --preset "${signing_keygrip}"
j_msg "-${notice}" -p -n "Done presetting cached passphrase; result:"
handle_result $? '' '' "$notice"

j_msg "-${notice}" -m "Done"
