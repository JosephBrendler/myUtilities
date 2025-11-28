#!/bin/bash
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_unicode

PN=$(basename $0)

checkroot

user=joe
win_user=joebr
rollup_file="/home/${user}/script/elrond_configs_rollup"
#target="${user}@gmki91:/home/${user}/"
target="${win_user}@joelaptop:C:/Users/${win_user}/Desktop/"
logFile="/home/${user}/router_health_check.data"
internal_dns_target="gmki91"
external_dns_target="google.com"

#-----[ functions ]--------------------------------------------
show-result() {
_result="$1"
if [ "$_result" -eq 0 ] ; then
  bremoji "$face_beam"
  echo -e -n " (${BGon}success!${Boff})"
else
  bremoji "$no_entry"
  echo -e -n " (${BRon}failed!${Boff})"
fi
right_status "$_result"
}


# initialize logFile
> "${logFile}"
log_separator "$(hostname)" "$PN"
date | tee -a "${logFile}"

# show status of services
log_separator "$PN" "(rc_status -a)"
rc-status -a | tee -a "${logFile}"

# show status of network interfaces
log_separator "$PN" "(ifconfig)"
ifconfig | tee -a "${logFile}"

# show status of firewall
log_separator "$PN" "(shorewall status)"
/etc/init.d/shorewall status | tee -a "${logFile}"

# show status of sockets
log_separator "$PN" "(ss -tuep)"
ss -tuamep | tee -a "${logFile}"

# show status of basic external resolution
log_separator "$PN" "(DNS resolution check)"
message "DNS external resolution check"
host -t A "$external_dns_target" | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show status of basic internal resolution
log_separator "$PN" "(DNS internal resolution check)"
message "DNS internal resolution check"
host -t A "$internal_dns_target" | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show firewall status
log_separator "$PN" "(iptables -vnL --line-numbers)"
iptables -vnL --line-numbers | tee -a "${logFile}"
log_handle_result $?; show-result $?
log_separator "$PN" "(ip route show)"
ip route show | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show DNS resolution functionality
log_separator "$PN" "(dig @127.0.0.1 google.com)"
dig @127.0.0.1 google.com | tee -a "${logFile}"
log_handle_result $?; show-result $?
# Verify DNS/DHCP daemon is running
log_separator "$PN" "(ps aux | grep -E 'dnsmasq|dhcpd')"
ps aux | grep -E 'dnsmasq|dhcpd' | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show status of dhcp leases
log_separator "$PN" "(DHCP leases check)"
message "DHCP leases check"
cat /var/lib/misc/dnsmasq.leases | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show status of vpn address resolution
log_separator "$PN" "(vpn address resolution check)"
message "vpn address resolution check"
cat /etc/hosts.d/20_openVPN_clients | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show status of vpn server
log_separator "$PN" "(vpn server check)"
message "vpn server check"
/etc/init.d/openvpn.server status | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show status of dmz ddns address resolution
log_separator "$PN" "(dmz ddns address resolution check)"
message "dmz ddns address resolution check"
cat /etc/hosts.d/30_ddns_clients | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show status of system resources
log_separator "$PN" "(system resources check)"
message "system resources check"
top -bn1 | head -n 5 | tee -a "${logFile}"
log_separator "$PN" "(Disk Usage)"
df -h | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show status of log file anomaly check
log_separator "$PN" "(Recent critical log entries)"
# Check last 50 lines of syslog for "error" or "warning"
grep -EiR 'error|warning' /var/log/ 2>/dev/null | grep -v portage | grep -v emerge | tee -a "${logFile}"
log_handle_result $?; show-result $?

# show sysstat logging reports
log_separator "$PN" "(sar CPU utilization trends)"
sar -u -f /var/log/sa/sa28 | tee -a "${logFile}"
log_handle_result $?; show-result $?
log_separator "$PN" "(sar network activity trends)"
sar -n DEV -f /var/log/sa/sa28 | tee -a "${logFile}"
log_handle_result $?; show-result $?
log_separator "$PN" "(sar memory/swap utilization trends)"
sar -r -f /var/log/sa/sa28 | tee -a "${logFile}"
log_handle_result $?; show-result $?

# convert report to pdf format
cat "${logFile}" | \
  enscript -o - | \
  ps2pdf - "${logFile}.pdf"

# transfer to target for assessment
message "transferring ${logFile} ..."
sudo -u "${user}" scp "${logFile}" "${target}" >/dev/null 2>&1
result=$?
log_handle_result $result
show-result $result
message "transferring ${logFile}.pdf ..."
sudo -u "${user}" scp "${logFile}.pdf" "${target}" >/dev/null 2>&1
result=$?
log_handle_result $result
show-result $result
