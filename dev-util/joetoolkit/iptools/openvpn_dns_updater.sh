#!/bin/bash
# openvpn_dns_updater.sh
# joe Brendler - 10 November 2020
# retrieves active openVPN client info from openvpn-status.log updates /etc/hosts.d/ file for dnsmasq
#
source /usr/sbin/script_header_joetoo

PN=$(basename $0)

log_file=/var/log/openvpn-status.log
openVPN_hosts_file="/etc/hosts.d/20_openVPN_clients"

#-----[ script "global" variables ]------------------
ipv4_subnet="192.168.63"
ipv6_prefix="fd62"
client_list=()  # client names
ip_list=()      # client vpn subnet ip address
ts_list=()      # timestamp: last reference this addr/route
ip_type_list=() # store 'ipv4' or 'ipv6' for each entry

line=""
ip_type=""
ip=""
client_raw=""
real_public_ip=""
timestamp=""
client_name=""

# regex whitespace patterns
W1="[[:space:]]+"  # one or more whitespace
WZ="[[:space:]]*"  # zero or more whitespace
P1="[[:print:]]+"  # one or more printable characters
PZ="[[:print:]]*"  # zero or more printable characters

VERBOSE=$TRUE
[ -z $verbosity ] && verbosity=2  # allow calling script to set this

#-----[ functions ]-----------------------------
read_routing_table() {
  # read lines of log_file in the client list section only
  CAPTURE=$FALSE

  while read line
  do
    # if this is the beginning of the routing table section, start capture
    [ "${line:0:7}" == "ROUTING" ] && CAPTURE=${TRUE}
    # if this is the beginning of the global section, stop capture
    [ "${line:0:6}" == "GLOBAL" ] && CAPTURE=${FALSE}

    # if capturing and the line starts with target subnet, add the ip and client to lists
    if [ ${CAPTURE} ] && ( \
        [ "${line:0:${#ipv4_subnet}}" == "${ipv4_subnet}" ] || \
        [ "${line:0:${#ipv6_prefix}}" == "${ipv6_prefix}" ] ) ; then

      # Determine ip address type
      if [ "${line:0:${#ipv4_subnet}}" == "${ipv4_subnet}" ]; then
        ip_type="ipv4"
      else
        ip_type="ipv6"
      fi

      #Extract IP (field 1) and client name (field 2)
      ip=$(echo $line | cut -d',' -f1)              # client's virtual address (vpn subnet ip)
      client_raw=$(echo $line | cut -d',' -f2)      # client's Common Name (from certificdate)
      real_public_ip=$(echo $line | cut -d',' -f3)  # client's public ip & port (we dont need this)
      timestamp=$(echo $line | cut -d',' -f4)       # timestamp: last time this route was referenced

      # Format client name for local standardization
      # (clients are all issued vpn certificates whose names are reported in openvpn-status.log
      #  each such certificant name has the form "Elrondclient_${client_name}"
      client_name=$(echo "${client_raw}" | sed 's/Elrondclient_//' )

      # append to arrays
      ip_list+=("${ip}")
      client_list+=("${client_name}")
      ts_list+=("${timestamp}")
      ip_type_list+=("${ip_type}")
    fi
  done < "${log_file}"
}

update_hosts_file() {
    # Combine client and IP lists, sort uniquely, and write to temporary file
    local temp_ipv4=$(mktemp)
    local temp_ipv6=$(mktemp)
    local temp_raw=$(mktemp)

    # add all the raw data to temp_file each ip/client_name pair as a nicely tab-separated hosts file entry
    for ((i=0; i<${#client_list[@]}; i++)); do
        # put data in 2 columns ip (20 char), client_name (20 char), timestamp (20 char)
        printf "%s\t%s\t%s\t%s\n" "${ip_list[i]}" "${client_list[i]}" "${ts_list[i]}" "${ip_type_list[i]}"
    done > "$temp_raw"

    # Process IPv4 Entries (grep picks only ipv4 entries)
    #   First de-duplicates by hostname (field 2), keeping only the last (newest) entry seen
    #   LC_COLLATE applied here ensures uppercase Z does not precede lowercase a
    #   Second awk prints in fixed-width columns appropriate for ipv4 address info
    grep -E "${W1}ipv4$" "$temp_raw" | \
        LC_COLLATE="en_US.UTF-8" awk -F '\t' '{last[$2]=$0} END {for (a in last) print last[a]}' |
#        LC_COLLATE="en_US.UTF-8" awk -F '\t' '{ printf "%-20s %-20s %-20s\n", $1, $2, $3 }' | \
        # re-do space needed is 4xoctet + 3x'.' = 15 + pad = 17 char
        LC_COLLATE="en_US.UTF-8" awk -F '\t' '{ printf "%-17s %-20s %-20s\n", $1, $2, $3 }' | \
        # Sort alphabetically by hostname. Hostname is now field 2, starting at column 22.
#        LC_COLLATE="en_US.UTF-8" sort -k1.22,2 > "$temp_ipv4"
        LC_COLLATE="en_US.UTF-8" sort -k1.19,2 > "$temp_ipv4"

    # Process IPv6 Entries (grep picks only ipv6 entries)
    #   First de-duplicates by hostname (field 2), keeping only the last (newest) entry seen
    #   LC_COLLATE applied here ensures uppercase Z does not precede lowercase a
    #   Second awk prints in fixed-width columns appropriate for ipv4 address info
    grep -E "${W1}ipv6$" "$temp_raw" | \
        LC_COLLATE="en_US.UTF-8" awk -F '\t' '{last[$2]=$0} END {for (a in last) print last[a]}' |
#        LC_COLLATE="en_US.UTF-8" awk -F '\t' '{ printf "%-40s %-20s %-20s\n", $1, $2, $3 }' | \
        # dont need 40 char (128bit 8xhextet + 7x':') since openvpn assigns shorthand addresses
        # of the form: fd62:6262:6263::xxxx - short for: fd62:6262:6263:0000:0000:0000:0000:xxxx
        # so space needed is 4xhextet + 4x':' = 20 + pad = 22 char
        LC_COLLATE="en_US.UTF-8" awk -F '\t' '{ printf "%-22s %-20s %-20s\n", $1, $2, $3 }' | \
         # Sort alphabetically by hostname. Hostname is now field 2, starting at column 42.
#        LC_COLLATE="en_US.UTF-8" sort -k1.42,2 > "$temp_ipv6"
        LC_COLLATE="en_US.UTF-8" sort -k1.24,2 > "$temp_ipv6"

    # Re-initialize openVPN hosts file with separator and IPv4 header
    echo -e -n "" > "${openVPN_hosts_file}"
#    echo -e "\n" > "${openVPN_hosts_file}"
#    echo -e "# ------------------------------------------------------------------" >> "${openVPN_hosts_file}"
#    echo "# /etc/hosts.d/20_openVPN_clients (IPv4 Section)" >> "${openVPN_hosts_file}"
    echo -e "# ------------------------------------------------------------------" >> "${openVPN_hosts_file}"
#    echo "# IP Address (20)    Hostname (20)        Timestamp (20)" >> "${openVPN_hosts_file}"
    echo "# IPv4 Addr (17)  Hostname (20)        Timestamp (20)" >> "${openVPN_hosts_file}"

    # Add the IPv4 content
    cat "$temp_ipv4" >> "${openVPN_hosts_file}"

    # Add separator and IPv6 header
#    echo -e "\n" >> "${openVPN_hosts_file}"
#    echo -e "# ------------------------------------------------------------------" >> "${openVPN_hosts_file}"
#    echo "# /etc/hosts.d/20_openVPN_clients (IPv6 Section)" >> "${openVPN_hosts_file}"
    echo -e "# ------------------------------------------------------------------" >> "${openVPN_hosts_file}"
#    echo "# IP Address (40)                         Hostname (20)        Timestamp" >> "${openVPN_hosts_file}"
    echo "# IPv6 Addr (22)       Hostname (20)        Timestamp (20)" >> "${openVPN_hosts_file}"

    # Add the IPv6 content
    cat "$temp_ipv6" >> "${openVPN_hosts_file}"

    # Clean up temporary files
    rm "$temp_ipv4" "$temp_ipv6" "$temp_raw"

    # Output the newly created hosts file content (optional, for logging/debug)
    cat "${openVPN_hosts_file}"

}

#-----[ main script ]----------------------------------------
checkroot
separator "$(hostname)" "${PN}"
[ ! -f "${openVPN_hosts_file}" ] && touch "${openVPN_hosts_file}"

read_routing_table

message "found [${#client_list[@]}] potential openvpn client entries"

update_hosts_file

/etc/init.d/dnsmasq reload
