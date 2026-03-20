#!/bin/bash
#
# run this on the router/firewall AND on another client
#
source /usr/sbin/script_header_joetoo

checkroot

PN=${0##*/}    # like =$(basename 0) but w/o subshell and function call

#-----[ variables ]-----------------------------------------
user="joe"
logFile="/var/log/${PN}.log"
validate_logfile

[ -z $verbosity ] && verbosity=2

if [ ! -f "${logFile}" ] ; then
    sudo touch "${logFile}"
    sudo chown "${user}:${user}" "${logFile}"
fi

command_sequence=(
'ping -c3 8.8.8.8'
'dig google.com'
'dig google.com AAAA'
'nslookup google.com'
'ping6 -c3 2607:f8b0:4004:c21::64'
)

#-----[ main script  ]-----------------------------------------

for command in "${command_sequence[@]}"; do
    echo
    echo "${command}"
    echo $(repeat '-' "${#command}")
    j_msg -${notice} -p -n "running ${command} (quietly)"
    # read the command into an array so it and its args can be run as an array
    read -r -a cmd <<< "$command"
    sudo -u "$user" "${cmd[@]}" >/dev/null 2>&1
    result=$?
    handle_result "$result" "good" "bad" ${notice}
    if [ $result -eq 0 ] ; then
        result_str="${BGon}Succeeded${Boff}"
    else
        result_str="${BRon}Failed${Boff}"
    fi
    j_msg -${notice} -p -M $idx_face_beam "${BYon}Connectivity test: [${Mon}${command}${BYon}] ${result_str}"
done
