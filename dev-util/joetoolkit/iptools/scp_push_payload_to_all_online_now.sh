#!/bin/bash

source /usr/sbin/script_header_joetoo

#-----[ variables ]-----------------------------------------------------------------------

PN=${0##*/}

user="joe"
joetoo_dns="elrond"

[ -z "$verbosity" ] && verbosity=$notice

ssh_port="22"

hosts_files=(
  /etc/hosts.d/14_ddns_ipv4
  /etc/hosts.d/16_ddns_ipv6
  /etc/hosts.d/30_ddns_clients
  /etc/hosts.d/20_openVPN_clients
)
hosts_files_str="${hosts_files[@]}"

host_list=()
payload=""
dest=""

FLAGGED=$FALSE
PARALLEL=$TRUE
PROGRESS=$FALSE

export TMPDIR="/dev/shm"        # use /dev/shm for performance advantage
declare -a deduped_hosts=()     # populate after validation and deduplication
declare -a selected_ip_list=()  # down-select from addresses associated with deduped hostnames

varlist="user joetoo_dns ssh_port lv.hosts_files_str verbosity"
varlist+=" bool.DEBUG bool.FLAGGED bool.PARALLEL bool.PROGRESS"
varlist+=" TMPDIR payload dest rlv.deduped_hosts_str"
#-----[ functions ]-----------------------------------------------------------------------

my_usage() {
  local msg="${BRon}usage${Boff}: ${_func_color}$PN${Boff}"
  msg+=" ${_data_color}<payload> </path/to/dest> [-s|--serial]${Boff}"
  j_msg -$notice -p "$msg"
  msg="${BYon}Options --${Boff}"
  j_msg -$notice -p "$msg"
  msg="${BMon} -s|--serial${Boff}${Con} ....: disable parallel processing"
  j_msg -$notice -m "$msg"
  msg="${BMon} -p|--progress${Boff}${Con} ..: display progress bar instead of numbered list"
  j_msg -$notice -m "$msg"
  msg="${BMon} -h|--help${Boff}${Con} ......: print this message"
  j_msg -$notice -m "$msg"
  msg="${BYon}Arguments --${Boff}"
  j_msg -$notice -p "$msg"
  msg="${BCon}<payload>${Boff}${Con}........: (optional) default: /home/${user}/payload"
  j_msg -$notice -m "$msg"
  msg="${BCon}</path/to/dest>${Boff}${Con}..: (optional) default: /home/${user}/"
  j_msg -$notice -m "$msg"
  msg="${BCon}no-arg default${Boff}${Con}...: ${Con}will push"
  msg+=" /home/${user}/payload (if exists) to /home/${user}/${Boff}"
  j_msg -$notice -m "$msg"
  die "exiting"
}

validate_input() {
  local -a cmdline=("$@")  # transfer cmdline to array
  local temp_args=()
  # guard clauses
  if [ $# -gt 4 ] ; then
    j_msg -$err "invalid args [$@]"
    my_usage
    fi
  if [ $# -le 1 ] && [ ! -f "/home/${user}/payload" ] ; then
    j_msg -$err "/home/${user}/payload not found"
    my_usage
  fi
  # parse command line for -s|--serial option
  for arg in "$@"; do
    case "$arg" in
      -s|--serial)    PARALLEL=$FALSE ;;
      -p|--progress)  PROGRESS=$TRUE ;;
      -h|--help)      my_usage ;;
      *) tmp_args+=("$arg") ;;  # return unhandled options to positional parameters
    esac
  done
  set -- "${tmp_args[@]}"
  payload="${1:-/home/${user}/payload}" && \
  dest="${2:-/home/${user}/}"
  # return status code of assignments by default
}

ssh_cat_retry() {
    local host="$1" file="$2"
    local max_attempts=8
    local attempt=1
    local wait_time=10

    while [ $attempt -le $max_attempts ]; do
        ssh -q "$host" cat "$file" 2>/dev/null && return 0
        j_msg -$warn "Retry $attempt/$max_attempts for $file on $host..."
        milli_sleep $wait_time
        attempt=$((attempt + 1))
        wait_time=$(( wait_time * 2 )) # Exponential backoff
    done
    return 1
}

ingest_hosts_files() {
  FLAGGED=$FALSE
  local -a tmp_ip_list=()
  for f in "${hosts_files[@]}"; do
    j_msg -$notice -p -n "ingesting [$f] to deduped_hosts array"
    # -t removes trailing newlines; -q silences banner; grep ignores comment lines; awk selects hostname column
    # (each iteration appends b/c -O ${#host_list[@]} sets a new starting index to read into the array)
    # sed to convert fqdn to hostname | sort to dedupe | sed to make all fqdn
    readarray -t -O "${#deduped_hosts[@]}" deduped_hosts < <(
      ssh_cat_retry "${joetoo_dns}" "$f" |
        grep -Ev "^${W0}#" |    # ignore comments
        awk '{print $2}' |      # get hostname/fqdn only
        sed 's|.brendler||' |   # convert fqdn to hostname
        sort -u |               # dedupe
        sed 's|$|.brendler|'    # convert all back to fqdn
    )
    handle_result $? "deduped count: ${#deduped_hosts[@]}" '' $notice || FLAGGED=$TRUE
    deduped_hosts_str="${deduped_hosts[@]}"
  done
  j_msg -$debug -p "(debug) dumping deduped_hosts ..."
  d_do 'for host in "${deduped_hosts[@]}"; do echo "$host"; done' $debug
  # parallel "Live" check using bash /dev/tcp (fastest)
  j_msg -$notice -p "Verifying recipients are online and choosing best address ..."
  for host in "${deduped_hosts[@]}"; do
    tmp_ip_list=()
    j_msg -$debug -p "checking host [${host}]"
    # use getent database to list ips for this host
    readarray -t -O "${#tmp_ip_list[@]}" tmp_ip_list < <(getent ahosts "$host" | awk '{print $1}' | uniq)
    # race these ips (ping both in background and pick the first respondent)
    winner_file=$(mktemp -p /dev/shm)
    for ip in "${tmp_ip_list[@]}"; do
      # use /dev/tcp/${ip}/${ssh_port} (tcp and ssh port) instead of ping (icmp) to reliably predict scp latency
      (timeout 0.5 bash -c "</dev/tcp/${ip}/${ssh_port}" && echo "$ip" >> "$winner_file") &>/dev/null &
    done  # tmp_ip_list
    wait  # wait for the winner or the 0.5s timeout
    best_ip=$(head -n1 "$winner_file")
    j_msg -$debug -p "best ip for host [${host}] is [$best_ip]"
    # wrap IPv6 addresses in square brackets (standard SSH/URI convention)
    #   to later distinguish the address from port - e.g. [fd62:6262:6262:0:2bff:4078:2153:8ebe]:22
    if [ -n "$best_ip" ]; then
      case "$best_ip" in
        *:*) selected_ip_list+=("[$best_ip]") ;;  # ipv6
        *)   selected_ip_list+=("$best_ip") ;;  # ipv4
      esac
    fi  # -n $best_ip
    rm -f "$winner_file"
  done  # deduped_hosts list

  j_msg -$info -m "read [${#deduped_hosts[@]}] hostnames; down-selected [${#selected_ip_list[@]}] ips"
  d_do 'for ip in "${selected_ip_list[@]}"; do echo "$ip"; done' $debug
  [ "$FLAGGED" ] && return 1
  return 0
}

sendit() {
  FLAGGED=$FALSE
  local total="${#host_list[@]}"
  local complete=0
  local tmp_dir=$(mktemp -dq)
  local hostsfile=$(mktemp -q)

  local msg="${BWon}pushing payload [${BBon}$payload${BWon}] to [${BMon}${#selected_ip_list[@]}${BWon}]"
  msg+=" recipients (${BYon}ctrl-c to cancel${BWon})${Boff}"
  j_msg -p "$msg"
  if [ $PARALLEL ]; then
    j_msg -$debug -p "(debug) in ${FUNCNAME[0]} PARALLEL branch"
    # populate hostsfile
    #printf '%s\n' "${host_list[@]}" > "$hostsfile"
    # use optimized ip address list instead
    printf '%s\n' "${selected_ip_list[@]}" > "$hostsfile"
    ## (opt1) use gnu parallel to send to all at the same time
    # printf "%s\n" "${host_list[@]}" | parallel -j $(nproc) scp -q "${payload}" "{}:${dest}"
    # (opt2) this can also be done by sending all scp jobs to the backgroud, monitor jobs -r | wc -l ...
    # (opt3) use net-misc/pssh pscp (parallel scp) and a /dev/shm tempfile for performance advantage
    # set trap to the background pscp on CTRL-C (and remove temp stuff)
    trap 'kill $pscp_pid 2>/dev/null; rm -rf "$tmp_dir" "$hostsfile"; exit 1' INT
    if [ $PROGRESS ]; then
      pscp -h "$hostsfile" -x "-o ConnectTimeout=5 -o BatchMode=yes" -o "$tmp_dir" "$payload" "$dest" &
      pscp_pid=$!
      # monitor with joetoo progress bar
      while kill -0 $pscp_pid 2>/dev/null; do
        # count how many files exist in the output directory
        complete=$(ls -1 "${tmp_dir}" | wc -l)
        progress_inline "$complete" "$total"
        sleep 1
      done
    else
      pscp -h "$hostsfile" -x "-o ConnectTimeout=5 -o BatchMode=yes" "$payload" "$dest"
    fi
  else
    j_msg -$debug -p "(debug) in ${FUNCNAME[0]} SERIAL branch"
    # dont parallel process - run jobs sequentially (in serial)
    # enable single ctrl-c to cancel entire for-loop
    trap "exit" INT
    for ip in "${selected_ip_list[@]}"; do
      j_msg -p -n "sending to ${ip}"
      scp -q "${payload}" "${ip}:${dest}"
      handle_result $? '' '' $notice || FLAGGED=$TRUE
    done
  fi
  rm -f "$hostsfile"
  rm -rf "$tmp_dir"

  [ "$FLAGGED" ] && return 1
  return 0
}

#-----[ main script ]-----------------------------------------------------------------------
checknotroot

validate_input "$@" || die "failed to validate_input"

separator "$(hostname)" "(scp push [$payload] to [$dest])"

if ! ingest_hosts_files ; then
  j_msg -$warn "ingest_hosts_files noted error(s)"
  confirm_continue_or_exit
fi

d_do 'show_config || die "failed to show_config"' $info

sendit || { j_msg -$warn -p "sendit() noted errors"; exit 1 ; }
exit 0
