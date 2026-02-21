#!/bin/bash
# not_on_dns_whitelist.sh
# Joe Brendler, 7 Sep 14
# list dnsmasq dns querries for domains not entered in dns_whitelist
#
source /usr/sbin/script_header_joetoo
BUILD="0.0.2 (20181023)"
WHITELIST="/var/log/dns_whitelist"
LOGFILE="/var/log/dnsmasq.log"
verbosity=5

# note sed makes space-delimitted structure predictable
pipe=" | grep from | /bin/sed 's/\ */\ /' | cut -d' '  -f7 | sort -h | uniq -c | sort -h"
build_pipe()
{
  local _lines
  readarray -t _lines < <(grep -v "^${W0}#" "${WHITELIST}")
  for (( i=0; i<${#_lines[@]}; i++ )); do
    debug_msg "$i:  ${_lines[i]}"
  # ignore commented or blank lines; otherwise add to piped "grep -v" chain
  [ ! -z $(echo $line | tr -d '[:space:]') ] && pipe+=" | grep -v \"${line}\""
  let i++
done < ${WHITELIST}

}

#---[ main script ]-------------------------
separator "not_on_dns_whitelist.sh ${BUILD}"
checkroot
build_pipe
[ "$#" -gt "0" ] && LOGFILE="$1"
info_msg "LOGFILE: $LOGFILE"

#if the logfile contains "old_logs/", use zcat
[ $( echo `expr match "$LOGFILE" 'old_logs/'`) -ne "0" ] && \
   loc_cmd="zcat" || loc_cmd="cat"

info_msg "pipe: $pipe"
echo
info_msg "cmd: ${loc_cmd} ${LOGFILE} ${pipe}"
echo
eval "${loc_cmd} ${LOGFILE} ${pipe}"
