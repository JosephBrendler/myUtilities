#!/bin/bash
# new_get_openVPN_client_info_for_dns.sh
# joe Brendler - 10 November 2020
# retrieve openVPN client info from log file and publish in hosts file for dnsmasq
#
#source /usr/local/sbin/script_header_brendlefly
source /usr/sbin/script_header_joetoo

log_file=/var/log/openvpn-status.log
hosts_file="/etc/hosts"
hosts_dir="/etc/hosts.d"
openVPN_hosts_file="${hosts_dir}/20_openVPN_hosts"

#-----[ local variables ]------------------
subnet="192.168.63"
client_list=()
ip_list=()
sorted_client_list=()
sorted_ip_list=()
wait_time=1  # how long to wait in ping-test (s)

VERBOSE=$TRUE
verbosity=2

#-----[ local functions ]-----------------------------
read_routing_table() {
  # read lines of log_file in the client list section only
  CAPTURE=$FALSE
  while read line
  do
    # if this is the routing table section, start capture
    [ "${line:0:7}" == "ROUTING" ] && CAPTURE=${TRUE}
    [ "${line:0:6}" == "GLOBAL" ] && CAPTURE=${FALSE}
    # if this is a route entry, add the ip and client to lists
    if [ ${CAPTURE} ] && [ "${line:0:${#subnet}}" == "${subnet}" ] ; then
      ip_list+=("$(echo $line | cut -d',' -f1)")
      client_list+=("$(echo $line | cut -d',' -f2 | sed 's/Elrondclient_//' )")
    fi
  done < ${log_file}
}

print_client_list() {
  for ((i=0; i<${#client_list[@]}; i++)); do echo "${client_list[i]} ${ip_list[i]}"; done
}

alphabetize_and_deduplicate() {
  # sort and eliminate duplicate identical entries
  while read myline
  do
    sorted_client_list+=("$(echo $myline | cut -d' ' -f1)")
    sorted_ip_list+=("$(echo $myline | cut -d' ' -f2)")
  done <<< $(print_client_list | sort -u)
}

validate() {
  # if a client is listed with more than one ip address, figure out which to use
  d_echo "in validate()..." 3
  for ((i=0; i<${#sorted_client_list[@]}; i++)); do
    d_echo "examining ${sorted_client_list[i]} ${sorted_ip_list[i]}" 3
    # if this ip is invalid, mark it so and move on, else look for dupes
    response="$(ping -c1 -w${wait_time} ${sorted_ip_list[i]})"
    result="$(echo ${response} | grep transmitted | cut -d',' -f3 | cut -d'%' -f1 | cut -d'.' -f1 | sed 's/[[:space:]]//g')"
    d_echo "  response i [${sorted_ip_list[i]}]:  ${response}" 3
    d_echo "  result i [${sorted_ip_list[i]}]:  ${result}" 3
    # if there was more than 75% packet loss, mark this ip as invalid (to be dropped from list)
    if [ $result -gt 75 ]; then
      sorted_ip_list[i]="invalid"
    fi
  done
}

update_hosts_file() {
  # re-initialize openVPN hosts file
  echo "# /etc/hosts.d/20_openVPN_hosts" > ${openVPN_hosts_file}
  # add each openVPN client to the the hosts file
  for ((i=0; i<${#sorted_client_list[@]}; i++))
  do
    [ ! "${sorted_ip_list[i]}" == "invalid" ] && \
       echo -e "${sorted_ip_list[i]} \t${sorted_client_list[i]}" >> ${openVPN_hosts_file}
  done
  # overwrite main hosts file by concatenating files in hosts directory
  cat ${openVPN_hosts_file}
  cat ${hosts_dir}/* > ${hosts_file}
}

#-----[ main script ]----------------------------------------
checkroot

read_routing_table
echo "initialized client_list with [${#client_list[@]}] members"
echo "initialized ip_list with [${#ip_list[@]}] members"
echo

alphabetize_and_deduplicate

validate

update_hosts_file

/etc/init.d/dnsmasq restart
