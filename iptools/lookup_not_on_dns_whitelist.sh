#!/bin/bash
# lookup_not_on_dns_whitelist
# Joe Brendler - 9 Aug 2014
# filter dns logs to identify queries for urls not on my whitelist (defined
# in the filter_log() function below, and lookup the ip address for each
#
# Note: You must emerge net-dns/bind-tools for nslookup functionality

# ---[ Include common functions ]---------------------------------
source /usr/local/sbin/script_header_brendlefly

# ---[ Define local variables ]-----------------------------------
BUILD="0.1 (20140809)"
LOGFILE="/var/log/messages"

SERVER="192.168.1.1"

# ---[ local functions ]------------------------------------------
filter_log()
{
# note that the "grep -v" commands in the pipe chain are the whitelist
message "filtering..."
./not_on_dns_whitelist.sh | grep -v "LOGFILE" | grep -v "not_on_dns_whitelist.sh" > temp
message "Found these urls, not on whitelist:"
cat temp
echo
}

ip_lookup()
{
message "ip_lookup..."
while read line
do
  # ignore lines beginning with * ( produced by message() ) and blank lines
  [ ! -z $(echo $line | tr -d '[:space:]') ] && \
    var=$(echo $(nslookup $(echo $line | cut -d' ' -f2) ${SERVER} | grep "Address" | grep -v "#" | cut -d' ' -f2 ))
  echo -e "$(echo $line | cut -d' ' -f2) \t$var"
done < ./temp
}

#---[ Main Script ]-----------------------
separator "Running lookup_not_on_dns_whitelist-${BUILD}"
check_root

message "Filtering the log file"
filter_log

message "Looking up hostnames for ip addresses found. Please wait..."
message "(This may take a few minutes to time out if the hosts are not on line)"
ip_lookup
echo

message "Cleaning up..."
rm temp
message "Done."
