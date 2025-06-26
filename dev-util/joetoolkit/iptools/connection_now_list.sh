#!/bin/bash
# connection_now_list.sh
# joe brendler
# 10 Apr 16

#---[ local variables ]-----------------
source /usr/sbin/script_header_joetoo
BUILD=0.0.001a
#conntrackFile=/proc/net/ip_conntrack
conntrackFile=/proc/net/nf_conntrack

list_connections()
{
for ip in $(cat ${conntrackFile} | grep -v "sport=53" | grep -v "dst=192.168" | cut -d'=' -f3 | cut -d' ' -f1)
do
  message "$(whois $ip | grep Organization | cut -d':' -f2) $ip"
done
}

#---[ main script ]----------------------
separator "connection_list-${BUILD}"
checkroot

list_connections | sort | uniq -c | sort -h
