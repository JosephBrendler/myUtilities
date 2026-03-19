#!/bin/bash
# not_on_dns_whitelist.sh
# Joe Brendler, 7 Sep 14
# list dnsmasq dns querries for domains not entered in dns_whitelist
#
source /usr/sbin/script_header_joetoo

#BUILD="0.0.2 (20181023)"
if [ -f /etc/joetoolkit/BUILD ]; then . /etc/joetoolkit/BUILD; else BUILD="0.0.3 (20260315)"; fi

WHITELIST="/var/log/dns_whitelist"
LOGFILE="/var/log/dnsmasq.log"
[ -z "$verbosity" ] && verbosity=${notice}

#---[ main script ]-------------------------
separator "not_on_dns_whitelist.sh ${BUILD}"
checkroot

# build grep chain safely - instead of old build_pipe()
whitelist_filter=("grep -v brendler")
while IFS= read -r line; do
    # skip lines that are empty (${line// } removes spaces) or comments
    [[ -z "${line// }" || "$line" =~ ^${W0}# ]] && continue
    whitelist_filter+=( "| grep -v $line" )
done < "$WHITELIST"

[ "$#" -gt "0" ] && LOGFILE="$1"
j_msg -${info} -m "LOGFILE: $LOGFILE"

#if the logfile contains "old_logs/", use zcat
if [ $( echo `expr match "$LOGFILE" 'old_logs/'`) -ne "0" ]; then
  _loc_cmd=("zcat")
else
  _loc_cmd=("cat")
fi

cmd=( "${_loc_cmd}" "$LOGFILE" )
# now run the pipeline safely
"${cmd[@]}" |
  grep 'query\[' |
  awk '{print $7}' |
  sort -h |
  uniq -c |
  sort -rh |
  grep -v -e "brendler" -f "$WHITELIST"
