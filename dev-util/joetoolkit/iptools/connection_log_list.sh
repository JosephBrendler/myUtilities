#!/bin/bash
# connection_log_list.sh
# joe brendler
# 10 Apr 16 (added geoip x Jan 17)

#---[ local variables ]-----------------
source /usr/sbin/script_header_joetoo
BUILD=0.0.02a
CONNTRACK_LOGFILE=/var/log/conntrackd-stats.log
CONNTRACK_OLD_LOGFILES=/var/log/old_logs/conntrackd-stats.log-*
tempfile1=/var/log/tempfile1
tempfile2=/var/log/tempfile2

count_connections()
{
  debug_msg "(debug) Inside count_connections"
  while read entry
  do
    mycount=$(echo $entry | cut -d' ' -f1)
    myip=$(echo $entry | cut -d' ' -f2)
    debug_echo_msg "(debug) looking up ip: ${myip}"
    # use whois or nslookup to determine the registered name
    # identified with the destination ip for these connections
    # Try whois first, and use nslookup if whois doesn't connect
    [[ $(whois $myip 2>/dev/null) ]] && result="ok" || result="false"
    debug_msg "(debug) whois result: $result"

    if [[ "$result" == "false" ]]
    then
        debug_msg "(debug) using nslookup..."
        # use nslookup (pull the name field, then drop the trailing period)
        nslookup_msg=$(nslookup $myip | grep -v "canonical" | grep name | cut -d'=' -f2 | cut -b2-)
        # if nslookup did not return a name, look for 'not find' message, else trim trailing period "."
        [[ -z "$nslookup_msg" ]] && \
            dst_id=$(nslookup $myip | grep -v "canonical" | grep "t find" | cut -d':' -f2 | cut -b2-) || \
            dst_id=${nslookup_msg:0:$((${#nslookup_msg}-1))}
        debug_msg "(debug) using nslookup result: $dst_id"
    else
        debug_msg "(debug) using whois..."
        # use whois result
        whois_msg=$(whois $myip | grep Organization | cut -d':' -f2 | sed 's/^\ *//' | sed 's/\n//')
        # if whois did not return an Organization, look for 'owner' instead
        debug_echo_msg "whois test: ${whois_msg}"
        [[ -z "$whois_msg" ]] && \
            dst_id=$(whois $myip | grep "owner:" | cut -d':' -f2 | sed 's/^\ *//' | sed 's/\n//') || \
            dst_id="$whois_msg"
        debug_msg "(debug) using whois result: $dst_id"
    fi

    geoip_msg="$(geoiplookup ${myip} | grep Country | cut -d: -f2)"

    echo "${mycount} connection(s) to ${myip} [ ${dst_id}, ${geoip_msg} ]"
  done < ${tempfile2}
}

#---[ main script ]----------------------
separator "connection_list-${BUILD}"
checkroot

geoipupdate.sh -f 2>/dev/null

# for all conntrackd logfiles, sort on and count the number of connections to each unique ip
debug_msg "(debug) Moving old logfiles to ${tempfile1}"
zcat ${CONNTRACK_OLD_LOGFILES} | grep -v "UNREPLIED" | cut -d'=' -f3 | cut -d' ' -f1 | grep -v 192.168 | sort | uniq -c > ${tempfile1}
debug_msg "(debug) Adding latest logfile to ${tempfile1}"
cat ${CONNTRACK_LOGFILE} | grep -v "UNREPLIED" | cut -d'=' -f3 | cut -d' ' -f1 | grep -v 192.168 | sort | uniq -c >> ${tempfile1}
debug_msg "(debug) Done adding"

debug_msg "(debug) Sorting all logfiles to ${tempfile2}"
# sort ips in descending numeric order of count of connections
cat ${tempfile1} | sort -hr > ${tempfile2}
# TODO aggregate in one total count, the separate counts of each unique dst ip, which result from all of the log files examined above

debug_msg "(debug) Running function count_connections"
count_connections
debug_msg "(debug) Done running function count_connections"

message "Cleaning up..."
d_do rm ${tempfile1} "$debug"
d_do rm ${tempfile2} "$debug"
message "Done."
