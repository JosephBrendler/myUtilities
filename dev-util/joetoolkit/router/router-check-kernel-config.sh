#!/bin/bash
# router-check-kernel-config     7 Nov 2025   (c) joe brendler   2025-9999
#
source /usr/sbin/script_header_joetoo

checkroot
PN=${0##*/}   # like =$(basename $0) but w/o subshell and function ccall

[ -z $verbosity ] && verbosity=${notice}

#-----[ variables ] -----------------------------------------------------------------

CONFIG=""

symbol_list=(
 IPV6_ROUTER_PREF
 IPV6
 INET6
 IPV6_ROUTER_PREF
 IPV6_MULTIPLE_TABLES
 NET_L3_MASTER_DEV BRIDGE
 NF_TABLES_IPV6
 BRIDGE_NF
 BRIDGE_NETFILTER
 NF_NAT
 NETFILTER_XT
 NF_CONNTRACK
 XFRM
 SLAB
 SLUB
)

#-----[ functions ] -----------------------------------------------------------------

run_search() {
    for x in ${symbol_list[@]} ; do
        j_msg -${notice} -mp "\n$x"
        j_msg -${notice} -mp -- $(repeat '-' ${#x})  # use -- end of options else the ---- string looks like one
        command_array=("${grep_command}" "-i" "${x}" "${CONFIG}")
        j_msg -${debug} -p "command_array: ${command_array[@]}"
        "${command_array[@]}" || die "failed to grep config for symbol $x"
    done
    j_msg -${notice} -mp   # newline
    return 0
}

get_config() {
    j_msg -${notice} -p "${BYon}These config files are found in the present working directory --${Boff}"
    d_do 'find ./ -iname "config" 2>/dev/null; echo' ${notice}
    local msg="${BYon}Supply path to ${LBon}CONFIG${BYon} or just press ${BMon}ENTER${BYon} to check /proc/config.gz${Boff}"
    read -p "$(echo -e ${msg})" CONFIG
    [ -z "${CONFIG}" ] && CONFIG="/proc/config.gz"

    #CONFIG="/tmp/portage/sys-kernel/gentoo-kernel-6.12.54/work/modprep/.config"

    if [[ "${CONFIG}" == "/proc/config.gz" ]] ; then
        grep_command="zgrep"
        j_msg -${notice} -p "for true, just set grep_commnd; [$grep_command]"
    else
        grep_command="grep"
        j_msg -${notice} -p "for false, just set grep_commnd; [$grep_command]"
    fi
    return 0
}

debug_break_marker() {
    bremoji "$explosion"
    echo -e " ${BMon}Debug Marker${Boff}"
    exit
}


#-----[ main script ] -----------------------------------------------------------------
separator "$(hostname)" "${PN}"

get_config || die "failed to get_config"
j_msg -${notice} -p "CONFIG: [$CONFIG]"

run_search || die "failed to run_search"

bremoji "$face_grin"
j_msg -${notice} -p "${BGon}Done${Boff}"
exit 0

#debug_break_marker

