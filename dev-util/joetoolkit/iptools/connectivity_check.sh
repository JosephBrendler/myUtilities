#!/bin/bash

source /usr/sbin/script_header_joetoo

# ensure a ping failure in output4[...]=$(ping ...| grep 'packets') returns *ping exit status
set -o pipefail

PN=$(basename $0)

declare -A results4
declare -A results6
declare -A output4
declare -A output6
declare -A elapsed4
declare -A elapsed6

nodes=(nuthuvia gmki92 sandbox raspicm46401 lcsp6402 rock5c6403 elrond google.com github.com)
#nodes=(nuthuvia google.com)  # shorter list for testing
longest=$(get_longest ${nodes[@]})

usage() {
  j_msg "${BRon}Usage:${Boff}${Gon} connectivity_check.sh [node[@]|-h] [count] [wait]"
  j_msg "\$1 can be -h : print this message, or it can be a quoted node list"
  j_msg "\$2 can be \"\" or a ping count (defaault = 3)"
  j_msg "\$3 can be \"\" or a wait time (sec to wait for each, default = 2)"
  j_msg "the script will run ping -4/6 -c${count} -W${wait} $node -"
  j_msg -p "   for both ipv4 and ipv6 - for each node in the nodelist"
  j_msg "${BYon}Example:${Boff} ${Gon}connectivity_check.sh ${BYon}\"elrond github.com\" ${BMon}1 1${Boff}"
  exit 1
}
show_result() {
  local result=$1 output="$2" elapsed="${3:-999}"
  local tx=0 rx=0 pct=100 ms="999999ms" sec=0 msg=""
  # parse output like: "3 packets transmitted, 3 received, 0% packet loss, time 2028ms"
  if [ ! -z "$output" ] ; then
    read -r tx _ _ rx _ pct _ _ _ ms <<< "$output"  # parse
  fi
  local clean_ms="${ms%ms}"
  sec=$(printf "%s\n" "scale=3; ${clean_ms:-999999} / 1000.0" | bc)  # note: trim the "ms" from ping time
  # check for at least one received packet, and thus don't take "cmd didnt crash" as success
  if [ $result -eq 0 ]  && [ "$rx" -gt 0 ]; then
    bremoji $face_beam
    j_msg -n -p "${BGon} Success${Boff}"
  else
    bremoji $no_entry
    j_msg -n -p "${BRon} Failed ${Boff}"
  fi
  elapsed_color="${BMon}"
  (( elapsed < 9 )) && elapsed_color="${BRon}"
  (( elapsed < 6 )) && elapsed_color="${BYon}"
  (( elapsed < 3 )) && elapsed_color="${BGon}"
  msg=" ${BBon}[ ${Con}${tx}/${rx} (${pct}) ${BMon}${sec} ${Boff}s ${BBon}]"
  msg+=" (${elapsed_color}$elapsed${BBon})${Boff}"
  j_msg -n -p "$msg"
}

getip4() {
  local node=$1
  local ip=$(getent ahostsv4 "$node" | awk '{print $1; exit}')
  if [ -z "$ip" ] ; then
    printf '%s' "${BRon}getent ahostsv4 reports no address for $node${Boff}"
  else
    printf '%s' "${BGon}$ip${Boff}"
  fi
}

getip6() {
  local node=$1
  local ip=$(getent ahostsv6 "$node" | awk '{print $1; exit}' | grep -v '::ffff:')
  if [ -z "$ip" ] ; then
    printf '%s' "${BRon}getent ahostsv6 reports no address for $node${Boff}"
  else
    printf '%s' "${BGon}$ip${Boff}"
  fi
}
#-----[ main script ]---------------------------------------------------
if [ "$1" = "-h" ] ; then usage
elif [ ! -z "$1" ] ; then nodes=($1)  # dont quote, so quoted list $1 becomes array
fi
count=${2:-3}  # default to 3 pings
wait=${3:-2}   # defailt wait no more than 2 sec for each

for node in "${nodes[@]}"; do
  # determine target: if it contains a dot, use as is; else append ".brendler" to make it a fqdn
  target="$node"
  [[ "$node" != *.** ]] && target="${node}.brendler"
  # check IPv4 connectivity
  j_msg -n "${BYon}pinging ${BCon}-4 ${BMon}${node}${Boff} "
  start=$SECONDS
  output4["$node"]=$(ping -4 -c"${count}" -W"${wait}" "$node" 2>/dev/null | grep 'packets')
  results4["$node"]=$?
  # provide debug output - ping result line and use getent to report preferred address
  j_msg -7 "\n(debug) output4: ${output4["$node"]}"
  j_msg -7 "Preferred ipv4 addr: $(getip4 "$node")"
  end=$SECONDS
  elapsed4["$node"]=$(( end - start ))
  show_result "${results4["$node"]}" "${output4["$node"]}" "${elapsed4["$node"]}"; printf '\n'
  # check IPv6 connectivity
  j_msg -n "${BYon}pinging ${BCon}-6 ${BMon}${target}${Boff} "
  start=$SECONDS
  output6["$node"]=$(ping -6 -c"${count}" -W"${wait}" "$target" 2>/dev/null | grep 'packets')
  results6["$node"]=$?
  # provide debug output - ping result line and use getent to report preferred address
  j_msg -7 "\n(debug) output6: ${output6["$node"]}"
  j_msg -7 "Preferred ipv6 addr: $(getip6 "$node")"
  end=$SECONDS
  elapsed6["$node"]=$(( end - start ))
  show_result "${results6["$node"]}" "${output6["$node"]}" "${elapsed6["$node"]}"; printf '\n'
done


separator "$PN" "(summary)"

offset1=$(( longest + 3 ))
offset2=$(( offset1 + 42 + 3 ))

# poor mans fixed-width columns
printf "${BCon}%s\r" "Node";
CUF $offset1; printf ' | %s\r' "IPv4 result [ tx/rx, % loss, time ]";
CUF $offset2; printf " | %s${Boff}\n" "IPv6 result [ tx/rx, % loss, time ]"

for node in "${nodes[@]}"; do
    printf '%s\r' "${BCon}${node}${Boff}";
    CUF $offset1; printf " | ";
    show_result "${results4["$node"]}" "${output4["$node"]}" "${elapsed4["$node"]}";
    printf '\r'
    CUF $offset2; printf " | ";
    show_result "${results6["$node"]}" "${output6["$node"]}" "${elapsed6["$node"]}";
    printf '\n'
done
