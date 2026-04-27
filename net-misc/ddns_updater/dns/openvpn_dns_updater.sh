#!/bin/bash
# openvpn_dns_updater.sh
# joe Brendler - 10 November 2020
# retrieves active openVPN client info from openvpn-status.log updates /etc/hosts.d/ file for dnsmasq
#
source /usr/sbin/script_header_joetoo

PN=${0##*/}   # like =$(basename $0) but w/o subshell and function call

log_file=/var/log/openvpn-status.log
#openVPN_hosts_file="/etc/hosts.d/20_openVPN_clients"
openVPN_hosts_file="/home/joe/test_openVPN_clients"

#-----[ script "global" variables ]------------------
ipv4_subnet="192.168.63"
ipv6_prefix="fd62"
domain="brendler"

TAB=$'\t'       # readable pre-coocked tab byte code

client_list=()  # client names
ip_list=()      # client vpn subnet ip address
ts_list=()      # timestamp: last reference this addr/route
ip_type_list=() # store 'ipv4' or 'ipv6' for each entry

line=""
ip_type=""
ip=""
client_raw=""
timestamp=""
client_name=""

# regex whitespace patterns
W1="[[:space:]]+"  # one or more whitespace
WZ="[[:space:]]*"  # zero or more whitespace
P1="[[:print:]]+"  # one or more printable characters
PZ="[[:print:]]*"  # zero or more printable characters

[ -z "${verbosity:-}" ] && verbosity="${notice}"  # allow calling script to set this

#-----[ functions ]-----------------------------
read_routing_table() {
  j_msg -$debug -p "in ${FUNCNAME[0]}"
  # read lines of log_file in the client list section only
  CAPTURE="$FALSE"

  # use null IFS to force read to not split but treat the entire line as one variable
  # -r (preserves trailing/leading whitespace and \s by disabling escape interpretation
  while IFS= read -r line
  do
    # if this is the beginning of the routing table section, start capture
    [ "${line:0:7}" = "ROUTING" ] && CAPTURE="${TRUE}"
    # if this is the beginning of the global section, stop capture
    [ "${line:0:6}" = "GLOBAL" ] && CAPTURE="${FALSE}"
    j_msg -$debug -p "CAPTURE: [$(TrueFalse $CAPTURE)]"
    j_msg -$debug -p "line: [$line]"
    # if capturing and the line starts with target subnet, add the ip and client to lists
    if [ "${CAPTURE}" ] && ( \
        [ "${line:0:${#ipv4_subnet}}" = "${ipv4_subnet}" ] || \
        [ "${line:0:${#ipv6_prefix}}" = "${ipv6_prefix}" ] ) ; then

      #Extract IP (field 1) and client name (field 2)
      # strip longest match for ',*' from the right - leaving ip e.g. fd62:6262:6263::1004
      ip="${line%%,*}"
      # strip shortest match for '*,' (ip and comma) from left, leaving remainder starting with name
      rem="${line#*,}"
      # strip longest match for ',*' from the right - leaving client raw name e.g. Elrondclient_raspi56403
      client_raw="${rem%%,*}"
      # ignore the uplink and peel timestamp from the right
      timestamp="${rem##*,}"

      # Format client name for local standardization
      # (clients are all issued vpn certificates whose names are reported in openvpn-status.log
      #  each such certificant name has the form "Elrondclient_${client_name}"
      # strip Elrondclient_ from the left - leaving name
      client_name="${client_raw#Elrondclient_}"

      # Determine ip address type
      case "$ip" in
        *:*) ip_type="ipv6" ;;
        *.*) ip_type="ipv4" ;;
        *) ip_type="invalid" ;;
      esac

      # for ipv6 addresses, append domain to hostname, to form fully qualified domain name (fqdn)
      if [ "$ip_type" = "ipv6" ]; then
        client_name="${client_name}.${domain}"
      fi
      j_msg -$debug -p "ip: $ip"
      j_msg -$debug -p "client_name: $client_name"
      j_msg -$debug -p "ip_type: $ip_type"
      # validate reachability before adding to the database
      # initial empirical results (≈50 hosts, local LAN):
      #   timeout 0.3 socat - TCP:"$ip":22,connect-timeout=0.3 &>/dev/null      ~0.20s total
      #   timeout 0.3 bash -c "echo > /dev/tcp/$ip/22" 2>/dev/null              ~2.8s total
      #   nc -z -w 1 "$ip" 22 2>/dev/null                                       ~4.2s total
      #   ping -W 1 -c 1 "$ip"                                                  ~5.5s total
      # actual in-script sytax and results --
      # tst=socat; case "$ip" in *:*) tgt="[${ip}]" ;; *.*) gt="${ip}" ;; *) tgt="" ;; esac
      # j_msg -$debug -p "testing tgt: $tgt"
      # if timeout 0.3 socat - TCP:"$tgt":22,connect-timeout=0.3 \
      #  1>/dev/null 2>/dev/null < /dev/null; then                                        3.210s (slowest; very finicky)
      # tst=devtcp; if timeout 0.3 bash -c "echo > /dev/tcp/$ip/22" 2>/dev/null; then     1.787s
      # tst=nc; if nc -z -w 1 "$ip" 22 2>/dev/null; then                                  1.348s (fastest)
      # tst=ping; if ping -W 1 -c 1 "$ip" &>/dev/null ; then                              2.602s
                        #
      # Chosen:
      #   - nc: fastest overall, lowest overhead - drops ipv6 occasionally
      #   - socat: slowest, should be fast, but very finnicky - drops ipv6 often
      #   - ping: best against false negatives; icmp not eq tcp reachability
      #   * devtcp: consistent; fast; stable
      #   - TCP port 22: earliest reliable service
      #   - probe IP (not hostname) to avoid DNS latency
      #   - consistent IPv6 behavior
      #   - minimal false-negatives in LAN sweeps
#       tst=ping; if ping -W 1 -c 1 "$ip" &>/dev/null ; then
       tst=devtcp; if timeout 0.3 bash -c "echo > /dev/tcp/$ip/22" 2>/dev/null; then
        j_msg -$debug -p "connectivity [$tst]-test result: success"
        # append to database - four parallel indexed arrays
        ip_list+=("${ip}")
        client_list+=("${client_name}")
        ts_list+=("${timestamp}")
        ip_type_list+=("${ip_type}")
      else
        j_msg -$debug -p "socat result: failure"
      fi  # connectivity validated
    fi  # capture mode
  done < "${log_file}"
}

update_hosts_file() {
    # Combine client and IP lists, sort uniquely, and write to temporary file
    local machine_temp_ipv4=$(mktemp)   # tab delimited to be more machine-readable
    local machine_temp_ipv6=$(mktemp)   # tab delimited to be more machine-readable
    local draft_hosts_file=$(mktemp)

    # add all the raw data to temp_file each ip/client_name pair as a nicely tab-separated hosts file entry
    for ((i=0; i<${#client_list[@]}; i++)); do
        # put data in 2 columns ip (20 char), client_name (20 char), timestamp (20 char)
        # (i.e. use tab delimiters to build nicely machine-readable data)
        printf "%s\t%s\t%s\t%s\n" "${ip_list[i]}" "${client_list[i]}" "${ts_list[i]}" "${ip_type_list[i]}"
    done > "$draft_hosts_file"

    # Process IPv4 Entries (grep picks only ipv4 entries)
    # (replaces the block above because "latest timestam" does not mean newest)
    # Old routes can have newer ts, so get the highest 4th octet since that is always
    #   the one openvpn assigned most recently. sort on hostname with secondary key on IP descending;
    #   since the rest of 192.168.63. is always identical, the most recent will be last, so
    #   first de-duplicates by hostname (field 2), keeping only the last (newest ip - field 1) entry
    # Note: explicitly use '\t' delimiter since the for loop above builds with tab delimiters and sort otherwise
    #   treats any whitespace as a delimtier (this is why previous key was -k1.19,2)
    #   LC_COLLATE applied here ensures uppercase Z does not precede lowercase a
    #   Second awk prints in fixed-width columns appropriate for ipv4 address info
    # get ipv4 only and sort by key1 hostname key2 ip (to get in recency order)
    grep -E "${W1}ipv4$" "$draft_hosts_file" | LC_COLLATE="en_US.UTF-8" sort -t "${TAB}" -k2 -k1,1 |  \
    # key on host name and keep only the last entry for each
    LC_COLLATE="en_US.UTF-8" awk -F '\t' '{last[$2]=$0} END {for (a in last) print last[a]}' | \
    # print fixed width (human-readable) output for file
    LC_COLLATE="en_US.UTF-8" awk -F '\t' '{ printf "%-17s %-20s %-20s\n", $1, $2, $3 }' | \
    # sort by hostname (needed again b/c de-duplication destroys order of grep | sort
    LC_COLLATE="en_US.UTF-8" sort -k2,2 > "$machine_temp_ipv4"

    # Process IPv6 Entries (grep picks only ipv6 entries)
    # (replaces the block above because "latest timestam" does not mean newest)
    # Old routes can have newer ts, so get the highest last hextet since that is always
    #   the one openvpn assigned most recently. sort on hostname with secondary key on IP descending;
    #   since the rest of fd62:62626263: is always identical, the most recent will be last, so
    #   first de-duplicates by hostname (field 2), keeping only the last (newest ip - field 1) entry
    # Note: explicitly use '\t' delimiter since the for loop above builds with tab delimiters and sort otherwise
    #   treats any whitespace as a delimtier (this is why previous key was -k1.19,2)
    #   LC_COLLATE applied here ensures uppercase Z does not precede lowercase a
    #   Second awk prints in fixed-width columns appropriate for ipv6 address info
    # get ipv6 only and sort by key1 hostname key2 ip (to get in recency order)
    grep -E "${W1}ipv6$" "$draft_hosts_file" | LC_COLLATE="en_US.UTF-8" sort -t "${TAB}" -k2 -k1,1 | \
    # key on host name and keep only the last entry for each
    LC_COLLATE="en_US.UTF-8" awk -F '\t' '{last[$2]=$0} END {for (a in last) print last[a]}' |
    # dont need 40 char (128bit 8xhextet + 7x':') since openvpn assigns shorthand addresses
    # of the form: fd62:6262:6263::xxxx - short for: fd62:6262:6263:0000:0000:0000:0000:xxxx
    # so space needed is 4xhextet + 4x':' = 20 + pad = 22 char
    # print fixed width (human-readable) output for file
    LC_COLLATE="en_US.UTF-8" awk -F '\t' '{ printf "%-22s %-25s %-20s\n", $1, $2, $3 }' | \
    # Sort alphabetically by hostname
    LC_COLLATE="en_US.UTF-8" sort -k2,2 > "$machine_temp_ipv6"

    # Re-use draft_hosts_file to prepare new fixed-width human-readable temp file
    #   for openVPN hosts file with separator and IPv4 header
    : > "$draft_hosts_file"   # safe truncate
    printf '%s\n' "# ------------------------------------------------------------------" >> "${draft_hosts_file}"
    printf '%s\n' "# IPv4 Addr (17)  Hostname (20)        Timestamp (20)" >> "${draft_hosts_file}"

    # Add the IPv4 content
    cat "$machine_temp_ipv4" >> "${draft_hosts_file}"

    # Add separator and IPv6 header
    printf '%s\n' "# ------------------------------------------------------------------" >> "${draft_hosts_file}"
    printf '%s\n' "# IPv6 Addr (22)       FQDN (25)                 Timestamp (20)" >> "${draft_hosts_file}"

    # Add the IPv6 content
    cat "$machine_temp_ipv6" >> "${draft_hosts_file}"

    # Clean up temporary files
    rm "$machine_temp_ipv4" "$machine_temp_ipv6"

    # remove draft_hosts_file by using mv as an atomic write to re-populate openVPN_hosts_file
    mv "$draft_hosts_file" "${openVPN_hosts_file}"

    # Output the newly created hosts file content (optional, for logging/debug)
    cat "${openVPN_hosts_file}"

}

#-----[ main script ]----------------------------------------
checkroot
separator "$(hostname)" "${PN}"
[ ! -f "${openVPN_hosts_file}" ] && touch "${openVPN_hosts_file}"

read_routing_table

j_msg -${notice} -p "found [${#client_list[@]}] potential openvpn client entries"

update_hosts_file

/etc/init.d/dnsmasq reload
Elrond ~ # 
