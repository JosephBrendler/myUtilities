#!/bin/bash
#
# run this on the router/firewall AND on another client
#
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_unicode

checkroot

PN=$(basename 0)

user="joe"
logFile="/var/log/${PN}.log"

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

for command in "${command_sequence[@]}"; do
    echo
    echo "${command}"
    echo $(repeat '-' "${#command}")
    if [ $verbosity -le 3 ] ; then
        message_n "running ${command} (quietly)"
        eval "sudo -u ${user} ${command} >/dev/null 2>&1"
    else
        message_n "running ${command}"
        eval "sudo -u ${user} ${command}"
    fi
    result=$?
    log_handle_result "$result" "good" "bad"
    if [ $result -eq 0 ] ; then
        bremoji $face_beam ; message "${BYon}Connectivity test: [${Mon}${command}${BYon}] ${BGon}Succeeded!${Boff}"
    else
        bremoji $explosion ; message "${BYon}Connectivity test: [${Mon}${command}${BYon}] ${BRon}Failed!${Boff}"
    fi
done
