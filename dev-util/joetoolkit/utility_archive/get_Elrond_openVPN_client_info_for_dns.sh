#!/bin/bash
# get_openVPN_client_info_for_dns.sh
# joe Brendler - 10 November 2020
# retrieve openVPN client info from log file and publish in hosts file for dnsmasq
#
log_file=/var/log/openvpn-status.log
hosts_file="/etc/hosts"
hosts_dir="/etc/hosts.d"
openVPN_hosts_file="${hosts_dir}/20_openVPN_hosts"

#-----[ local variables ]------------------
client_list=()
ip_list=()
TRUE='true'
FALSE=''

#-----[ local functions ]-----------------------------
get_client_list() {
  # read lines of log_file in the client list section only
  CAPTURE=$FALSE
  while read line
  do
    # if this is the client list section, start capture
    length=${#line};  trim=${line%%"CLIENT"*}; index=${#trim}
    [[ ${index} -lt ${length} ]] && CAPTURE=${TRUE}
    # if this is the routing table section, stop capture
    length=${#line};  trim=${line%%"ROUTING"*}; index=${#trim}
    [[ ${index} -lt ${length} ]] && CAPTURE=${FALSE}
    # add just the Elrondclient_name to the client list // trim the "Elrondclient_" that I use
    [[ ${CAPTURE} ]] && client_list+=($(echo "${line}" | grep Elrondclient_ \
                           | cut -d',' -f1 | sed 's/Elrondclient_//'))
  done < ${log_file}
}

get_ip_list() {
  # read lines of log_file in the client list section only
  # look only for lines pertaining to client identified in $1 argument
  for ((i=0; i<${#client_list[@]}; i++))
  do
    CAPTURE=$FALSE
    while read line
    do
      # if this is the routing table section, start capture
      length=${#line};  trim=${line%%"ROUTING"*}; index=${#trim}
      [[ ${index} -lt ${length} ]] && CAPTURE=${TRUE}
      # if this is the global stats section, stop capture
      length=${#line};  trim=${line%%"GLOBAL"*}; index=${#trim}
      [[ ${index} -lt ${length} ]] && CAPTURE=${FALSE}
      # add just the ip address to the ip list
      if [[ ${CAPTURE} ]]
      then
        remnant=$(echo "${line}" | grep "${client_list[i]}" | cut -d',' -f1)
        [[ ${#remnant} -gt 0 ]] && ip_list[i]="${remnant}"
      fi
    done < ${log_file}  # while loop
  done #for loop
}

print_client_list() {
  for ((i=0; i<${#client_list[@]}; i++))
  do
    echo "${client_list[i]} [${ip_list[i]}]"
  done
}

update_hosts_file() {
  # re-initialize openVPN hosts file
  echo "# /etc/hosts.d/20_openVPN_hosts" > ${openVPN_hosts_file}
  # add each openVPN client to the the hosts file
  for ((i=0; i<${#client_list[@]}; i++))
  do
    echo "${ip_list[i]}     ${client_list[i]}" >> ${openVPN_hosts_file}
  done
  # overwrite main hosts file by concatenating files in hosts directory
  cat ${openVPN_hosts_file}
  cat ${hosts_dir}/* > ${hosts_file}
}

#-----[ main script ]----------------------------------------
get_client_list
echo "initialized client_list with [${#client_list[@]}] members"
get_ip_list
echo "initialized ip_list with [${#ip_list[@]}] members"
update_hosts_file

/etc/init.d/dnsmasq restart
