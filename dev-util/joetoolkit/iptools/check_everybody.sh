#!/bin/bash
source /usr/sbin/script_header_joetoo
#checknotroot

PN=${0##*/}   # basename
if [ -f /etc/joetoolkit/BUILD ]; then . /etc/joetoolkit/BUILD; else BUILD="0.0.1"; fi

dns="elrond.brendler"
user="joe"

separator "$(hostname)" "${PN}-${BUILD}"

# use an indexed array to ingest all of the dns's hosts files at once
declare -a lines
readarray -t lines < <(sudo -u "$user" ssh -q "$dns" cat /etc/hosts.d/*)

# use an associative array (hostnames keyed on ip addr) to thus hold both values in one array
declare -A targets

# iterate through all lines of the hosts files
for line in "${lines[@]}"; do
    # read the whole line, assign ip and host; ignore iface and timestamp
    read -r ip host iface ts_rest <<<"$line"
#   echo "ip: [$ip] host: [$host] iface: [$iface] ts_rest: [$ts_rest]"
    [[ -z "$ip" || "$ip" == \#* ]] && continue # Skip empty/comments
    targets["$ip"]="$host"
done
j_msg "-${info}" "ingested [${#targets[@]}] targets"

ups=0; downs=0
# feed the grouped output (below) into a while loop in the current shell
# in order to be able to scan the output and count total ups and downs
# (cant be done in subshell because that variable is gone when subshell exits)
while read -r line; do
    # print the line to stdout (and/or log)
    j_msg "-${notice}" -p "$line"
    # Strip ANSI colors before checking the status
    # (Color codes can interfere with "Up" matching)
    clean_line=$( printf '%s\n' "$line" | strip_ansi )
    case "$clean_line" in
        *is\ Up)   (( ups++ )) ;;
        *is\ Down) (( downs++ )) ;;
    esac
done < <(  # substitute the process below (actual parallel scan) into the while loop above
{ for ip in "${!targets[@]}"; do (
      host="${targets[$ip]}"
      { timeout 1 bash -c "</dev/tcp/${ip}/22" && \
        echo -e "${Mon}${ip} ${Bon}(${Boff}${Con}${host}${BBon})${Boff} is ${BGon}Up${Boff}" || \
        echo -e "${Mon}${ip} ${Bon}(${Boff}${Con}${host}${BBon})${Boff} is ${BRon}Down${Boff}" ;
      } 2>/dev/null &
  ) ; done; wait;
} | sed "/^${W0}$/d"
)
msg="complete. ${BBon}[${BMon}$ups${BBon}] ${BGon}up${Boff} |"
msg+=" ${BBon}[${BMon}$downs${BBon}] ${BRon}down${Boff}"
j_msg "-${notice}" -M "$idx_face_beam" "$msg"
