#!/bin/bash
# router-check-kernel-config     7 Nov 2025   (c) joe brendler   2025-9999
#
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_unicode

checkroot
PN=$(basename $0)

VERBOSE=$TRUE
[ -z $verbosity ] && verbosity=5

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
        echo ;
        echo $x;
        echo $(repeat '-' ${#x});
        command_array=(${grep_command} "${x}" "${CONFIG}")
        "${command_array[@]}" || die "failed to grep config for symbol $x"
    done
    echo
    return 0
}

get_config() {
    echo
    message "${BYon}These config files are found in the present working directory --${Boff}"
    find ./ -iname "config" 2>/dev/null
    echo
    local msg="${BYon}Supply path to ${LBon}CONFIG${BYon} or just press ${BMon}ENTER${BYon} to check /proc/config.gz${Boff}"
    read -p "$(echo -e ${msg})" CONFIG
    [ -z "${CONFIG}" ] && CONFIG="/proc/config.gz"

    #CONFIG="/tmp/portage/sys-kernel/gentoo-kernel-6.12.54/work/modprep/.config"

    if [[ "${CONFIG}" == "/proc/config.gz" ]] ; then
        grep_command="zgrep -i"
        d_message "for true, just set grep_commnd; [$grep_commnd]" 5
    else
        grep_command="grep -i"
        d_message "for false, just set grep_commnd; [$grep_commnd]" 5
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
d_message "CONFIG: [$CONFIG]" 5

run_search || die "failed to run_search"

bremoji "$face_grin"
echo -e "${BGon}Done${Boff}"
exit 0

#echo "VERBOSE: [$VERBOSE] verbosity: [$verbosity]"
#debug_break_marker

