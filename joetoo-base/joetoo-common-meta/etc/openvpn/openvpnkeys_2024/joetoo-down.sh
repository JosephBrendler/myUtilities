#!/bin/sh
# /etc/openvpn/openvpnkeys_2024/joetoo-down.sh
# dual-stack DNS removal for joetoo architecture

_log_prefix="[vpn-dns-down]"
_debug_log_file="/tmp/joetoo-updown.debug.log"
echo "(debug) running joetoo-down.sh" > "${_debug_log_file}"

# initialize localized variable for exit status
jd_status=0

# submit to openresolv - printf pipes the payload to openresolv on stdin;
#   -d means "delete" from database for "$dev" (which openvpn sets to tun0)
#   (after which openresolv re-merges this with info from other interfaces
#    and resolf.conf.head / tail, to write the actual resolv.conf located
#    by link /etc/resolv.conf --> /run/resolvconf/resolv.conf )
#   (like the standard gnu down.sh script, the fallback path restores the ".sv"
#    saved copy of the old /etc/resolv.conf that its up.sh created,
#    but that allows whichever interface brought an update most recently
#    to over-writet others in a three+ interface situation; so use of the
#    net-dns/openresolv package and the the pipeline submission method is
#    cleaner/safer and reversible in brendler-up/down.sh)
if [ -x /sbin/resolvconf ]; then
    /sbin/resolvconf -d "${dev}"
    jd_status=$?
else
    # FALLBACK: Restore the specific backup created for this device
    if [ -e /etc/resolv.conf."${dev}".sv ]; then
        mv /etc/resolv.conf."${dev}".sv /etc/resolv.conf
        jd_status=$?
    fi
fi

# clean up localized variables
unset -v _log_prefix

# removed to separte script installed by net-misc/ddns
# DIAGNOSTIC: Capture OpenVPN Environment
#{
#    printf '%s\n' "---[ (down) OpenVPN Env Debug: $(date) ]---"
#    env | grep -E 'ifconfig|ip|remote|local|dev' | sort
#    printf '%s\n' "-------------------------------------"
#} >> "${_debug_log_file}"
#echo "(debug)(down) ifconfig_local: ${ifconfig_local}] should be populated by openvpn" >> "${_debug_log_file}"
#echo "(debug)(down) ifconfig_ipv6_local: ${ifconfig_ipv6_local}] should be populated by openvpn" >> "${_debug_log_file}"
## ddns removal hook
#if [ -x /usr/sbin/ddns-update ]; then
#    # Remove IPv4 Tunnel Address
#    if [ -n "${ifconfig_local}" ]; then
#        /usr/sbin/ddns-update del "${ifconfig_local}" "${dev}"
#    fi
#    # Remove IPv6 Tunnel Address
#    if [ -n "${ifconfig_ipv6_local}" ]; then
#        /usr/sbin/ddns-update del "${ifconfig_ipv6_local}" "${dev}"
#    fi
#fi

exit ${jd_status}

