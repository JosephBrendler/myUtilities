#!/bin/bash

source /usr/sbin/script_header_joetoo

checkroot

PN=${0##*/}

signing_keyring_dir="/root/.gnupg"

signing_pubkey_dir="${signing_keyring_dir%/}/public-keys.d"
signing_lock="${signing_pubkey_dir%/}/pubring.db.lock"

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
