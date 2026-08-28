#!/bin/bash
#
# script for periodically updating a hosts list for addresses that otherwise frequenly fail first DoT lookup via stubby
#

#-----[ variables ]-------------------------------------------------------------------------------
TRUE=0; FALSE=''   #....# basis of pseudo-booleans, if used (since script_header_joetoo not loaded)
PN=${0##*/}   #.........# basename of current script
if [ -f /etc/joetoolkit/BUILD ]; then
    . /etc/joetoolkit/BUILD;  # use build number of joetoolkit
else
     BUILD="0.0.0"      # fallback build number
fi
TAG="${PN}-${BUILD}"    # for logging
LOG_FACILITY="local5"   # consolidate with dns and ddns log info (/var/log/dnsmasq.log)

# only let root do this (like "isroot" but script_header_joetoo not loaded)
[ "$(id -u)" -eq 0 ] || { echo "Must be root"; exit 1 ; }

slow_piggy_lookup_cache_hosts_file="/etc/hosts.d/50_slow_piggy_lookup_cache"

ip_col_width=40 #.............# xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx = 39
fqdn_colwidth=30 #............# github.githubassets.com = 23

dig_tries="1" #...............# how may times to try each dig
dig_timeout="3" #.............# seconds for each dig to wait
stubby_addr="127.0.0.1"  #....# use loop
stubby_port="53000" #.........# port for stubby local DNS listener (stubby forwards upstream using DoT)

cname_lookup_max_retries="30" # maximum CNAME lookup attempts before using expected fallback
                              # note: each failed lookup can take dig_timeout sec

# build regex pattern to match ipv4 address
# digit . group 3 times, followed by digit
# (note: with . inside[], this avoids passing awk x w/o \ escape -v cant handle
ipv4_re='^([0-9]+[.]){3}[0-9]+$'
# build regex pattern to match ipv6 address
# zero+ hex-digit, then :, then zero+ chars that are either hex-digit or :
ipv6_re='^[[:xdigit:]]*:[[:xdigit:]:]*$'

# assemble arguments for dig command (minus A or AAAA indicator)
dig_args=( "@${stubby_addr}" -p "${stubby_port}" "+short" )
dig_args+=( "+tries=${dig_tries}" "+timeout=${dig_timeout}" )

# assemble baseline awk arguments
base_awk_args=( -v iw="$ip_col_width" )
base_awk_args+=( -v fw="$fqdn_colwidth" )
declare -a awk_args=()

# use an associative array to take note of sites known to NOT have ipv6 (no AAAA records)
declare -A no_aaaa=(
    [github.com]=1
    [forums.gentoo.org]=1
)

# set up expected value of cnamed sites, for fallback
declare -A expected_cnames=(
    [wiki.gentoo.org]="goshawk.gentoo.org"
    [bugs.gentoo.org]="vulture.gentoo.org"
)

# set up another associative array for the aliases for the above cnames (assign in actual lookup below)
declare -A alias_for_cname=()

#-----[ functions ]-------------------------------------------------------------------------------
timestamp() { printf '%s\n' "$(date +'%Y-%m-%d_%H:%M:%S')" ; }   # (script_header_joetoo not loaded)

cnamed_site() {
    # try really hard to look these up because I KNOW they exist but are cnamed
    local site="$1"
    local answer=""
    local count=0
    local msg=""
    # for dig here, dont use +short, and ask dig for a structured answer section and select only a genuine CNAME resource record (RR)
    # dig -h | grep -E 'time|tries|all|answer'
    #     +timeout=###        (Set query timeout) [5]
    #     +tries=###          (Set number of UDP attempts) [3]
    #     +[no]all    (Set or clear all display flags)
    #     +[no]answer         (Control display of answer section)
    local -a cname_dig_args=( "@${stubby_addr}" -p "${stubby_port}" )
    cname_dig_args+=( "+tries=${dig_tries}" "+time=${dig_timeout}" )
    cname_dig_args+=( "+noall" "+answer" )
    while [[ -z $answer && $count -lt $cname_lookup_max_retries ]]; do
        answer=$(
            dig "${cname_dig_args[@]}" CNAME "$site" 2>/dev/null |   #....# lookup
                    awk '$4 == "CNAME" {   #..............................# select only the line matching CNAME
                        ans = $5   #......................................# select field 5 (contains the actual cname)
                        sub(/[.]$/, "", ans)   #..........................# substitute '' to drop the trailing .
                        print ans   #.....................................# put ans on stdout so answer=$( can read it
                        exit
                    }'
            )
        (( count++ ))
        # sleep a second, unless an answer has been obtained or timeout reached
        [[ -z $answer && $count -lt $cname_lookup_max_retries ]] && sleep 1
    done
    # fallback - log failure but use expected values
    if [ -z "$answer" ] ; then
        answer="${expected_cnames[$site]}"
        msg="(warning) CNAME record lookup failed for [${site}] after [$count] attempts; used expected_cname: [${answer}]"
        logger -p "${LOG_FACILITY}.warning" -t "${TAG}" "$msg"
    fi
    # return answer on stdout
    printf '%s\n' "$answer"
}

build_slow_piggy_list() {
    # maintain the list of such slow_piggies here
    # (note: it is not that they are slow, it is somehow hard for stubby DoT to reliably resolve them
    #  so it may be more accurate to say that stubby is the piggy)
    #
    local piglet="" cname=""
    # start with github sites
    slow_piggies=(
        github.com
        github.githubassets.com
        raw.github.com
    )
    # append static gentoo sites
    slow_piggies+=(
        gentoo.org
        forums.gentoo.org
    )
    # now append aliased gentoo sites
    # goshawk.gentoo.org  # CNAME for wiki.gentoo.org
    # vulture.gentoo.org  # CNAME for bugs.gentoo.org
    # note "${!assoc_array[@]}" lists the keys indexing the associative array, not the values
    for piglet in "${!expected_cnames[@]}"; do
        # get the cname from the cnamed_site function
        cname="$(cnamed_site "$piglet")"
        # append it to the list
        slow_piggies+=( "$cname" )
        # also add this piglet as an alias for this cname in the alias_for_cname array
        alias_for_cname["$cname"]="$piglet"
    done
}

#-----[ main script ]-----------------------------------------------------------------------------
# use a tempfile to accumulate records, so an atomic write update is possible at conclusion
tmp=$(mktemp /tmp/50slow_piggy_lookup_cache.XXXXXX) || { echo "failed to mktemp"; exit 1 ; }
# give it proper permissions now
chmod 644 "$tmp" || { rm -f "$tmp"; echo "failed to chmod 644 $tmp"; exit 1 ; }

# assemgle the slow_piggies array
build_slow_piggy_list

# iterate through sites listed above and look up ip addresses
for piggy in "${slow_piggies[@]}" ; do
    # first record the alias for this piggy (if any) so that alias can also get any discovered ip address(es)
    alias="${alias_for_cname[$piggy]:-}"
    # look up ipv4 and 1pv6 address(es) for this piggy,
    # bypassing local cache and look up address from stubby with dig_args formed above
    # (redirect stderr and filter to ensure capture only valid addrs
    #  ^[ char class consists only of 1 or more hex digits : . ]$ )
    dig_out_a=$(
        {
            dig "${dig_args[@]}" A "$piggy"
        } 2>/dev/null | grep -E "${ipv4_re}"
    )
    if [ -n "$dig_out_a" ]; then
        # if the lookup succeeded, then form hosts file entries and append to the tempfile
        # iterate through records in dig output
        comment="# $(timestamp) - new record"
        while read -r ip ; do
            # append hosts file entry with fixed width columns to tempfile
            printf "%-${ip_col_width}s %-${fqdn_colwidth}s %s\n" "$ip" "$piggy" "$comment" >> "$tmp"
            # if there is an alias for this piggy, then append a line to the hosts file for that alias, too
            if [ -n "$alias" ]; then
                printf "%-${ip_col_width}s %-${fqdn_colwidth}s %s\n" "$ip" "$alias" "$comment" >> "$tmp"
            fi
        done <<< "$dig_out_a"
    else
        # if the lookup failed, retain the existing records for this piggy
        retained="" # (re)initialize
        comment=" (old) lookup failed at "
        if [ -f "$slow_piggy_lookup_cache_hosts_file" ]; then
            awk_args=( "${base_awk_args[@]}" -v host="$piggy" -v pattern="$ipv4_re" -v ts="$(timestamp)" -v cmt="$comment" -v alias="$alias" )
            retained=$(
                awk "${awk_args[@]}" '
                    # fqdn must match exactly; ip just match family 4/6 regex; use implicit concatenation for new comment ($4 is old ts)
                    $2 == host && $1 ~ pattern {
                        printf "%-*s %-*s %s\n", iw, $1, fw, $2, "# " $4 cmt ts
                        # if there is an alias for this piggy, print a record for that, too
                        if (alias != "") printf "%-*s %-*s %s\n", iw, $1, fw, alias, "# " $4 cmt ts
                    }
               ' "$slow_piggy_lookup_cache_hosts_file"
            )
        fi   # -f hosts file
        # if not null, post updated retained record to hosts file with last known connection time for stubby
        if [ -n "$retained" ]; then
            printf '%s\n' "$retained" >> "$tmp"
            # log the stubby lookup failure
            logger -p "${LOG_FACILITY}.notice" -t "${TAG}" "(notice) A record lookup failed for ${piggy}; retained old record(s)"
        else
            # log stubby lookup failure AND failure to find retained record
            logger -p "${LOG_FACILITY}.warning" -t "${TAG}" "(warning) A record lookup failed for ${piggy}; no old A records available"
        fi   # -n $retained
    fi   # -n dig output

    # same as above, but for ipv6 (AAAA)
    #   skip for sites know to NOT have ipv6 (no AAAA records)
    #   (i.e. site name record not found (=1) in associative array)
    if [[ ! ${no_aaaa[$piggy]} ]]; then
        dig_out_aaaa=$(
            {
                dig "${dig_args[@]}" AAAA "$piggy"
            } 2>/dev/null | grep -E "${ipv6_re}"
        )
        if [ -n "$dig_out_aaaa" ]; then
            # if the lookup succeeded, then form hosts file entries and append to the tempfile
            # iterate through records in dig output
            comment="# $(timestamp) - new record"
            while read -r ip ; do
                # append hosts file entry with fixed width columns to tempfile
                printf "%-${ip_col_width}s %-${fqdn_colwidth}s %s\n" "$ip" "$piggy" "$comment" >> "$tmp"
                # if there is an alias for this piggy, then append a line to the hosts file for that alias, too
                if [ -n "$alias" ]; then
                    printf "%-${ip_col_width}s %-${fqdn_colwidth}s %s\n" "$ip" "$alias" "$comment" >> "$tmp"
                fi
            done <<< "$dig_out_aaaa"
        else
            # if the lookup failed, retain the existing records for this piggy
            retained="" # (re)initialize
            comment=" (old) lookup failed at "
            if [ -f "$slow_piggy_lookup_cache_hosts_file" ]; then
                awk_args=( "${base_awk_args[@]}" -v host="$piggy" -v pattern="$ipv6_re" -v ts="$(timestamp)" -v cmt="$comment" -v alias="$alias" )
                retained=$(
                    awk "${awk_args[@]}" '
                        # fqdn must match exactly; ip just match family 4/6 regex; use implicit concatenation for new comment ($4 is old ts)
                        $2 == host && $1 ~ pattern {
                            printf "%-*s %-*s %s\n", iw, $1, fw, $2, "# " $4 cmt ts
                            # if there is an alias for this piggy, print a record for that, too
                            if (alias != "") printf "%-*s %-*s %s\n", iw, $1, fw, alias, "# " $4 cmt ts
                        }
                   ' "$slow_piggy_lookup_cache_hosts_file"
                )
            fi   # -f hosts file
            # if not null, post updated retained record to hosts file with last known connection time for stubby
            if [ -n "$retained" ]; then
                printf '%s\n' "$retained" >> "$tmp"
                # log the stubby lookup failure
                logger -p "${LOG_FACILITY}.notice" -t "${TAG}" "(notice) AAAA record lookup failed for ${piggy}; retained old record(s)"
            else
                # log stubby lookup failure AND failure to find retained record
                logger -p "${LOG_FACILITY}.warning" -t "${TAG}" "(warning) AAAA record lookup failed for ${piggy}; no old AAAA records available"
            fi   # -n $retained
        fi   # -n dig output
    fi   # no_aaaa

done

# perform atomic write to preclude "use while slowly writing" challenge otherwise, or log error
if ! mv "$tmp" "$slow_piggy_lookup_cache_hosts_file"; then
    logger -p "${LOG_FACILITY}.err" -t "${TAG}" "(err) Failed to replace ${slow_piggy_lookup_cache_hosts_file}"
    rm -f "$tmp"
    exit 1
fi
