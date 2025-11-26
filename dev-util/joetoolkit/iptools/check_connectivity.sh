#!/bin/bash
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_unicode
_fam=""
_action="ping"
# if family is specified, use it
case "$1" in "4"|"6") _fam="-$1"; shift;; "-4"|"-6") _fam="$1"; shift;; esac
# if target is specified, use it
target="${1:-elrond.brendler}"
[ ! -z "$_fam" ] && _action="$_action $_fam"
message_n "$_action ${LBon}${target}${Boff} "
eval "$_action -c3 -W5 ${target}" >/dev/null 2>&1;
if [ $? -eq 0 ]; then
  bremoji "$face_beam"; echo -e -n " (${Gon}success!${Boff})"; result=0
else
  bremoji "$no_entry"; echo -e -n " (${Ron}failure!${Boff})"; result=1
fi;
right_status "$result"
