#!/bin/bash
source /usr/sbin/script_header_joetoo
wait=1
VERBOSE=$TRUE
verbosity=3

[[ $# -gt 1 ]] && echo "Too many arguments" && exit 1
[[ -z $1 ]] && interface="eth0" || interface="$1"

CLR
CUP 10 10
echo -n "Carrier status: "
SCP
while [[ $TRUE ]]
do
  echo -n "          "; RCP
#  cat /proc/self/net/dev | grep -i '${interface}' | awk '{print $1 $15}'
  [[ $(cat /proc/self/net/dev | grep -i ${interface} | awk '{print $15}') -eq 0 ]] && status="up" || status="down"
  echo -en $(status_color $status)${status}${Boff}
  RCP
  sleep ${wait}
done
