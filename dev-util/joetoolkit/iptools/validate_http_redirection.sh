#!/bin/bash
# validate_http_redirection.sh   (c) joe brendler  2026-7860
# first ingest an associative array of all hosts known by the dns,
# tnen use socat to do a port 80 scan to identify hosts serving http,
# then use curl -I to verify a 302 Found in http response header
source /usr/sbin/script_header_joetoo
checknotroot

PN=${0##*/}   # basename
if [ -f /etc/joetoolkit/BUILD ]; then . /etc/joetoolkit/BUILD; else BUILD="0.0.1"; fi

dns="elrond.brendler"

separator "$(hostname)" "${PN}-${BUILD}"

# use an indexed array to ingest all of the dns's hosts files at once
declare -a lines
j_msg "-${notice}" -p -n "[$(timestamp)] ${BCon}Ingesting${Boff} dns records"
readarray -t lines < <(ssh -q "$dns" cat /etc/hosts.d/*)
handle_result $? "ingested [${#lines[@]}] lines" "" || die "failed to ingest dns records"

# use an associative array (hostnames keyed on ip addr) to thus hold both values in one array
declare -A targets

#---{ functions ]------------------------------------------------------------
validate_redirect() {
    local _target="" _curl_out=""
    # use curl to validate redirection on _target ($1)
    if [ -n "$1" ] ; then
        # get the ip address (col 1 until j_msg prefixes output)
        case "$1" in *:*) _target="[${1}]";; *) _target="$1";; esac
        # use curl to verify redirection by lookig for 301 or 302 in the response header
        # -I: document info only from response header
        # -g: switch off globbing (--globoff) else [ ] is interpreted as a range of addresses
        #     rather than an ipv6 addr, though curl wont understand ipv6 w/o brackets
        _curl_out=$(curl -g -I http://"${_target}" 2>/dev/null)
        case "$_curl_out" in
          HTTP*301*|HTTP*302*) return 0 ;;   # redirected
          *                  ) return 2 ;;   # not redirected
        esac
    else
        return 1   # empty _target
    fi
}

# iterate through all lines of the hosts files
j_msg "-${notice}" -p -n "[$(timestamp)] ${BCon}Forming${Boff} associative target array"
for line in "${lines[@]}"; do
    # read the whole line, assign ip and host; ignore iface and timestamp
    read -r ip host _ _ <<<"$line"   # _ _ stands in for iface timestam and whatever else
#   echo "ip: [$ip] host: [$host] iface: [$iface] ts_rest: [$ts_rest]"
    [[ -z "$ip" || "$ip" == \#* ]] && continue # Skip empty/comments
    targets["$ip"]="$host"
done
handle_result $? "arrayed [${#targets[@]}] targets" "" || die "failed to generate target array"

j_msg "-${notice}" -p "[$(timestamp)] ${BCon}Running parallel connectivity/redirect validation${Boff}"
j_msg "-${notice}" -m " ${BYon}connectivity command${Boff}: [timeout 1 bash -c \"</dev/tcp/\${ip}/80\" ... &]"
j_msg "-${notice}" -m " ${BYon}redirect validation command${Boff}: [curl -g -I http://\"${_target}\" 2>/dev/null]"
ups=0; downs=0 redirs=0
# feed the grouped output (below) into a while loop in the current shell
# in order to be able to scan the output and count total ups and downs
# (cant be done in subshell because that variable is gone when subshell exits)
while read -r line; do
    _target=""
    # Strip ANSI colors before checking the status and then validating redirection if up
    # (Color codes can interfere with "Up" matching)
    clean_line=$( printf '%s\n' "$line" | strip_ansi )
    case "$clean_line" in
        *is\ Up*)   (( ups++ ))
            if [[ "$clean_line" == *"Redirected"* && "$clean_line" != *"Not Redirected"* ]]; then
                (( redirs++ ))
            fi ;;
        *is\ Down*) (( downs++ )) ;;
    esac
    # print the line to stdout (and/or log)
    j_msg "-${notice}" -p "$line"
done < <(  # substitute the process below (actual parallel scan) into the while loop above
{ for ip in "${!targets[@]}"; do (
      host="${targets[$ip]}"
      # initiate formatted msg for this target
      msg="${Mon}${ip} ${Bon}(${Boff}${Con}${host}${BBon})${Boff} is "
      # group the connectivity check and call to validate_redirect, complete msg format
      { if timeout 1 bash -c "</dev/tcp/${ip}/80"; then
            msg+="${BGon}Up${Boff}"
            if validate_redirect "$ip" ; then
                msg+=" and ${BGon}Redirected${Boff}"
            else
                msg+="but ${BRon}Not Redirected${Boff}"
            fi
        else
            msg+="${BRon}Down${Boff}"
        fi
        # now do one write to output
        printf '%s\n' "$msg"
      } 2>/dev/null &
  ) ; done; wait;
} | sed "/^${W0}$/d"
)
msg="[$(timestamp)] ${BYon}Complete${Boff}. ${BBon}[${BMon}$ups${BBon}] ${BGon}up${Boff} |"
msg+=" ${BBon}[${BMon}$downs${BBon}] ${BRon}down${Boff}"
msg+=" ${BBon}[${BMon}$redirs${BBon}] ${BYon}redirected${Boff}"
j_msg "-${notice}" -p -M "$idx_face_beam" "$msg"
