#!/bin/bash
source /usr/sbin/script_header_joetoo

PN=${0##*/}   # basename

_fam=""
_action=(ping)

usage() { j_msg -${err} "usage: $PN [-[4|6]] [<target>]"; exit 1; }

# if family is specified, use it ; ignore $2 - maybe use below after shift
#case "$1" in
#   "-h") usage;;
#   "4"|"6") _fam="-$1"; shift;;
#   "-4"|"-6") _fam="$1"; shift;;
#esac

# if target is specified, use it
#target="${1:-elrond.brendler}"
#[ ! -z "$_fam" ] && _action+=("$_fam")
#_action+=("-c1" "-W2" "$target")
#j_msg -${notice} -p -n "${BYon}$_action${Boff} ${Con}${target}${Boff} "
##"$_action" -c1 -W2 "${target}" >/dev/null 2>&1
#"${_action[@]}" >/dev/null 2>&1
#handle_result $? "$bin_face_beam success!" "$bin_no_entry failure!" ${notice}

# to do: convert to either /dev/tcp or nc -zv, include -P --parallel flag (and rename "jping")



declare -A targets
for x in /etc/hosts.d/*; do
    while read -r ip host rest; do
        [[ -z "$ip" || "$ip" == \#* ]] && continue # Skip empty/comments
        targets["$ip"]="$host"
    done < "$x"
done
echo "ingested: [${#targets[@]}]"
{ for ip in "${!targets[@]}"; do (
      host="${targets[$ip]}"
      { timeout 1 bash -c "</dev/tcp/${ip}/22" && \
        echo -e "${ip} (${host}) is ${BGon}Up${Boff}" || \
        echo -e "${ip} (${host}) is ${BRon}Down${Boff}" ;
      } 2>/dev/null &
  ) ; done; wait;
} | sed "/^${W0}$/d"



#{ for ip in "${target_list[@]}"; do (
#    { timeout 1 bash -c "</dev/tcp/${ip}/22" && \
#      echo -e "${BGon}${ip} is Up${Boff}" || \
#      echo -e "${BRon}${ip} is Down${Boff}" ;
#    } 2>/dev/null &
#  ) ; done; wait;
#} | grep -v "^${W0}$" --color=never; echo
