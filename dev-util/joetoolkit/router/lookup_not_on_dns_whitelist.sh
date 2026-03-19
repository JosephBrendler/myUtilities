#!/bin/bash
# lookup_not_on_dns_whitelist
# Joe Brendler - 9 Aug 2014
# filter dns logs to identify queries for urls not on my whitelist (defined
# in the filter_log() function below, and lookup the ip address for each
#
# Note: You must emerge net-dns/bind-tools for nslookup functionality

# ---[ Include common functions ]---------------------------------
source /usr/sbin/script_header_joetoo

# ---[ Define local variables ]-----------------------------------
BUILD="0.1 (20140809)"
LOGFILE="/var/log/messages"

SERVER="192.168.1.1"

# ---[ local functions ]------------------------------------------
filter_log()
{
# note that the "grep -v" commands in the pipe chain are the whitelist
j_msg -${notice} -p "filtering..."
./not_on_dns_whitelist.sh | grep -v "LOGFILE" | grep -v "not_on_dns_whitelist.sh" > temp
j_msg -${notice} -p "Found these urls, not on whitelist:"
cat temp | sed 's|^|   |'
j_msg -${notice} -mp  # newline
}

ip_lookup()
{
j_msg -${notice} -p "ip_lookup..."
while read line
do
  # ignore lines beginning with * ( produced by j_msg() ) and blank lines
  [ ! -z $(printf '%s\n' $line | tr -d '[:space:]') ] && \
    var=$(printf '%s\n' $(nslookup $(printf '%s\n' $line | \
       cut -d' ' -f2) ${SERVER} | grep "Address" | grep -v "#" | cut -d' ' -f2 ))
  j_msg -${notice} -mp "$(printf '%s\n' $line | cut -d' ' -f2) \t$var"
done < ./temp
}

#---[ Main Script ]-----------------------
separator "Running lookup_not_on_dns_whitelist-${BUILD}"
checkroot

j_msg -${notice} -p "Filtering the log file"
filter_log

j_msg -${notice} -p "Looking up hostnames for ip addresses found. Please wait..."
j_msg -${notice} -p "(This may take a few minutes to time out if the hosts are not on line)"
ip_lookup
echo

j_msg -${notice} -p "Cleaning up..."
rm temp
j_msg -${notice} -p "Done."
