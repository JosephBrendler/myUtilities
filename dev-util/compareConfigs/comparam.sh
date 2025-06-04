#!/bin/bash
# comparam
# 5 November 2016 - Joe Brendler
# Compare the setting of a single parameter in two kernel config files
# Arguments:
#   $1 = kernel_config_name_1
#   $2 = kernel_config_name_2
#   $3 = parameter

#DEBUG="true"
DEBUG="false"
source /usr/local/sbin/script_header_brendlefly
BUILD="0.0"

kern1="$1"; kern2="$2"; param="$3"
[ "$DEBUG" == "true" ] && echo "hello"
[ "$DEBUG" == "true" ] && echo "1: $kern1"
[ "$DEBUG" == "true" ] && echo "2: $kern2"
[ "$DEBUG" == "true" ] && echo "3: $param"


ans1="$(grep -i $param $kern1)"
ans2="$(grep -i $param $kern2)"
[ "$DEBUG" == "true" ] && echo "ans1: $ans1"
[ "$DEBUG" == "true" ] && echo "ans2: $ans2"

title1="config"
title2="parameter"

[ ${#kern1} -gt ${#kern2} ] && col2=$((${#kern1} + 2)) || col2=$((${#kern2} + 2))
[ $col2 -lt ${#title1} ] && col2=$((${#title1} + 2))
[ "$DEBUG" == "true" ] && echo "len1: ${#kern1}"
[ "$DEBUG" == "true" ] && echo "len2: ${#kern2}"
[ "$DEBUG" == "true" ] && echo "ttl1: ${#title1}"
[ "$DEBUG" == "true" ] && echo "col2: $col2"
[ "$DEBUG" == "true" ] && echo "$(repeat '.' 6)"

echo
separator "comparam-$BUILD" "comparing: $param"
echo
message ${BYon}"___$title1$(repeat '_' $(($col2 - ${#title1} - 3))) [ ${title2} ]"${Boff}
message ${LBon}"$kern1$(repeat '.' $(($col2 - ${#kern1}))) ${Boff}[ $ans1 ]"
message ${BMon}"$kern2$(repeat '.' $(($col2 - ${#kern2}))) ${Boff}[ $ans2 ]"
