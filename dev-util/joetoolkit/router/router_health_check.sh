#!/bin/bash
source /usr/sbin/script_header_joetoo

PN=${0##*?}   # like =$(basename $0) but w/o subshell and function call

checkroot

user=joe
win_user=joebr
rollup_file="/home/${user}/script/elrond_configs_rollup"
#target="${user}@gmki91:/home/${user}/"
target="${win_user}@joelaptop:C:/Users/${win_user}/Desktop/"
logFile="/home/${user}/router_health_check.data"
validate_logfile
internal_dns_target="gmki91"
external_dns_target="google.com"
LOGGING=$TRUE

#-----[ functions ]--------------------------------------------
show-result() {
handle_result $1 "$bin_face_beam success" "$bin_no_entry failed" ${notice}
}


# initialize logFile '> file' = cat NULL to file (truncate/initialize empty)
> "${logFile}"
separator "$(hostname)" "$PN"
date | tee -a "${logFile}"

# show status of services
separator "$PN" "(rc_status -a)"
rc-status -a | tee -a "${logFile}"

# show status of network interfaces
separator "$PN" "(ifconfig)"
ifconfig | tee -a "${logFile}"

# show status of firewall
separator "$PN" "(shorewall status)"
/etc/init.d/shorewall status | tee -a "${logFile}"

# show status of sockets
separator "$PN" "(ss -tuep)"
ss -tuamep | tee -a "${logFile}"

# show status of basic external resolution
separator "$PN" "(DNS resolution check)"
j_msg -${notice} -p "DNS external resolution check"
host -t A "$external_dns_target" | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show status of basic internal resolution
separator "$PN" "(DNS internal resolution check)"
j_msg -${notice} -p "DNS internal resolution check"
host -t A "$internal_dns_target" | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show firewall status
separator "$PN" "(iptables -vnL --line-numbers)"
iptables -vnL --line-numbers | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?
separator "$PN" "(ip6tables -vnL --line-numbers)"
ip6tables -vnL --line-numbers | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?
separator "$PN" "(ip route show)"
ip route show | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?
separator "$PN" "(ip -6 route show)"
ip route show | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show DNS resolution functionality
separator "$PN" "(dig @127.0.0.1 google.com)"
dig @127.0.0.1 google.com | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?
# Verify DNS/DHCP daemon is running
separator "$PN" "(ps aux | grep -E 'dnsmasq|dhcpd')"
ps aux | grep -E 'dnsmasq|dhcpd' | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show status of dhcp leases
separator "$PN" "(DHCP leases check)"
j_msg -${notice} -p "DHCP leases check"
cat /var/lib/misc/dnsmasq.leases | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show status of vpn address resolution
separator "$PN" "(vpn address resolution check)"
j_msg -${notice} -p "vpn address resolution check"
cat /etc/hosts.d/20_openVPN_clients | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show status of vpn server
separator "$PN" "(vpn server check)"
j_msg -${notice} -p "vpn server check"
/etc/init.d/openvpn.server status | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show status of dmz ddns address resolution
separator "$PN" "(dmz ddns address resolution check)"
j_msg -${notice} -p "dmz ddns address resolution check"
cat /etc/hosts.d/30_ddns_clients | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show status of system resources
separator "$PN" "(system resources check)"
j_msg -${notice} -p "system resources check"
top -bn1 | head -n 5 | tee -a "${logFile}"
separator "$PN" "(Disk Usage)"
df -h | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show status of log file anomaly check
separator "$PN" "(Recent critical log entries)"
# Check last 50 lines of syslog for "error" or "warning"
grep -EiR 'error|warning' /var/log/ 2>/dev/null | grep -v portage | grep -v emerge | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# show sysstat logging reports
separator "$PN" "(sar CPU utilization trends)"
#sar -u -f /var/log/sa/sa28 | tee -a "${logFile}"
sar -u -f /var/log/sa/sa$(date '+%d') | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?
separator "$PN" "(sar network activity trends)"
#sar -n DEV -f /var/log/sa/sa28 | tee -a "${logFile}"
sar -n DEV -f /var/log/sa/sa$(date '+%d') | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?
separator "$PN" "(sar memory/swap utilization trends)"
#sar -r -f /var/log/sa/sa28 | tee -a "${logFile}"
sar -r -f /var/log/sa/sa$(date '+%d') | tee -a "${logFile}"
handle_result $? ${notice}; show-result $?

# convert report to pdf format
cat "${logFile}" | \
  enscript -o - | \
  ps2pdf - "${logFile}.pdf"

# transfer to target for assessment
j_msg -${notice} -p "transferring ${logFile} ..."
sudo -u "${user}" scp "${logFile}" "${target}" >/dev/null 2>&1
result=$?
handle_result $result
show-result $result
j_msg -${notice} -p "transferring ${logFile}.pdf ..."
sudo -u "${user}" scp "${logFile}.pdf" "${target}" >/dev/null 2>&1
result=$?
handle_result $result
show-result $result
