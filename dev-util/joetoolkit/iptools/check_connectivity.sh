#!/bin/bash
source /usr/sbin/script_header_joetoo

PN=${0##*/}   # basename

_fam=""
_action=(ping)

usage() { j_msg -${err} "usage: $PN [-[4|6]] [<target>]"; exit 1; }

# if family is specified, use it ; ignore $2 - maybe use below after shift
case "$1" in
   "-h") usage;;
   "4"|"6") _fam="-$1"; shift;;
   "-4"|"-6") _fam="$1"; shift;;
esac

# if target is specified, use it
target="${1:-elrond.brendler}"
[ ! -z "$_fam" ] && _action+=("$_fam")
_action+=("-c1" "-W2" "$target")
j_msg -${notice} -p -n "${BYon}$_action${Boff} ${Con}${target}${Boff} "
#"$_action" -c1 -W2 "${target}" >/dev/null 2>&1
"${_action[@]}" >/dev/null 2>&1
handle_result $? "$bin_face_beam success!" "$bin_no_entry failure!" ${notice}
