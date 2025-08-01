#!/bin/bash
# not_on_dns_whitelist.sh
# Joe Brendler, 7 Sep 14
# list dnsmasq dns querries for domains not entered in dns_whitelist
#
source /usr/sbin/script_header_joetoo
BUILD="0.0.2 (20181023)"
WHITELIST="/var/log/dns_whitelist"
LOGFILE="/var/log/dnsmasq.log"
VERBOSE=$TRUE
verbosity=0

# note sed makes space-delimitted structure predictable
#pipe=" | grep from | /bin/sed 's/\  /\ /' | cut -d\" \"  -f7 | sort -h | uniq -c | sort -h"
pipe=" | grep from | /bin/sed 's/\ */\ /' | cut -d' '  -f7 | sort -h | uniq -c | sort -h"
build_pipe()
{
i=1
while read line; do
  [ "$DEBUG" == "true" ] && echo "$i:  $line"
  # ignore commented or blank lines; otherwise add to piped "grep -v" chain
  [ "${line:0:1}" != "#" ] && [ ! -z $(echo $line | tr -d '[:space:]') ] && pipe=${pipe}" | grep -v \"${line}\""
  let i++
done < ${WHITELIST}

}

#---[ main script ]-------------------------
separator "not_on_dns_whitelist.sh ${BUILD}"
checkroot
build_pipe
[ "$#" -gt "0" ] && LOGFILE="$1"
message "LOGFILE: $LOGFILE"

#if the logfile contains "old_logs/", use zcat
[ $( echo `expr match "$LOGFILE" 'old_logs/'`) -ne "0" ] && \
   loc_cmd="zcat" || loc_cmd="cat"

d_message "pipe: $pipe" 2
echo
d_message "cmd: ${loc_cmd} ${LOGFILE} ${pipe}" 1
echo
eval "${loc_cmd} ${LOGFILE} ${pipe}"
