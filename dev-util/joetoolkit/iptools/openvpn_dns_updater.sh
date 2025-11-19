#!/bin/bash
# openvpn_dns_updater.sh
# joe Brendler - 10 November 2020
# retrieves active openVPN client info from openvpn-status.log updates /etc/hosts.d/ file for dnsmasq
#
source /usr/sbin/script_header_joetoo

PN=$(basename $0)

log_file=/var/log/openvpn-status.log
openVPN_hosts_file="/etc/hosts.d/20_openVPN_clients"

#-----[ local variables ]------------------
subnet="192.168.63"
client_list=()  # client names
ip_list=()      # client vpn subnet ip address
ts_list=()      # timestamp: last reference this addr/route

VERBOSE=$TRUE
[ -z $verbosity ] && verbosity=2  # allow calling script to set this

#-----[ local functions ]-----------------------------
read_routing_table() {
  # read lines of log_file in the client list section only
  CAPTURE=$FALSE
  local line
  while read line
  do
    # if this is the beginning of the routing table section, start capture
    [ "${line:0:7}" == "ROUTING" ] && CAPTURE=${TRUE}
    # if this is the beginning of the global section, stop capture
    [ "${line:0:6}" == "GLOBAL" ] && CAPTURE=${FALSE}

    # if captureing and the line starts with target subnet, add the ip and client to lists
    if [ ${CAPTURE} ] && [ "${line:0:${#subnet}}" == "${subnet}" ] ; then
      #Extract IP (field 1) and client name (field 2)
      local ip=$(echo $line | cut -d',' -f1)              # client's virtual address (vpn subnet ip)
      local client_raw=$(echo $line | cut -d',' -f2)      # client's Common Name (from certificdate)
      local real_public_ip=$(echo $line | cut -d',' -f3)  # client's public ip & port (we dont need this)
      local timestamp=$(echo $line | cut -d',' -f4)       # timestamp: last time this route was referenced

      # Format client name for local standardization
      # (clients are all issued vpn certificates whose names are reported in openvpn-status.log
      #  each such certificant name has the form "Elrondclient_${client_name}"
      local client_name=$(echo "${client_raw}" | sed 's/Elrondclient_//' )

      # append to arrays
      ip_list+=("${ip}")
      client_list+=("${client_name}")
      ts_list+=("${timestamp}")
    fi
  done < "${log_file}"
}

update_hosts_file() {
    # Combine client and IP lists, sort uniquely, and write to temporary file
    local temp_file=$(mktemp)

    # add to temp_file each ip/client_name pair as a nicely formatted hosts file entry
    for ((i=0; i<${#client_list[@]}; i++)); do
        # put data in 2 columns ip (20 char), client_name (20 char), timestamp (20 char)
        printf "%-20s %-20s %-20s\n" "${ip_list[i]}" "${client_list[i]}" "${ts_list[i]}"
    done | \
        # Use awk to de-duplicate by hostname (field 2), keeping only the last (newest) entry seen
        # LC_COLLATE applied here ensures uppercase Z does not precede lowercase a
        LC_COLLATE="en_US.UTF-8" awk '{last[$2]=$0} END {for (a in last) print last[a]}' | \
            # Sort alphabetically by hostname using key/column position (avoid confusing punctuation in col 1)
            LC_COLLATE="en_US.UTF-8" sort -k1.22,2

#    done | LC_COLLATE="en_US.UTF-8" sort -k1.22,2 -k1.55,3  > "$temp_file"
#    done | sort -k2.2 > "$temp_file"

    # Re-initialize openVPN hosts file with a header
    echo "# /etc/hosts.d/20_openVPN_hosts" > "${openVPN_hosts_file}"

    # Add the now-sorted and formatted content of the temp file
    cat "$temp_file" >> "${openVPN_hosts_file}"

    # Clean up temporary file
#    rm "$temp_file"

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
