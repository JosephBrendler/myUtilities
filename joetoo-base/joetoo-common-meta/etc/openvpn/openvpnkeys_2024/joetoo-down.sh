#!/bin/sh
# /etc/openvpn/openvpnkeys_2024/joetoo-down.sh
# dual-stack DNS removal for joetoo architecture

_log_prefix="[vpn-dns-down]"
_debug_log_file="/tmp/joetoo-up.debug.log"

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

echo "(debug)(down) ifconfig_pool_remote_ip: {$ifconfig_pool_remote_ip] should be populated by openvpn"> "${_debug_log_file}"
echo "(debug)(down) ifconfig_pool_remote_ip6: {$ifconfig_pool_remote_ip6] should be populated by openvpn" > "${_debug_log_file}"
# ddns removal hook
if [ -x /usr/bin/ddns-update ]; then
    # Remove IPv4 Tunnel Address
    if [ -n "${ifconfig_pool_remote_ip}" ]; then
        /usr/bin/ddns-update del "${ifconfig_pool_remote_ip}" "${dev}"
    fi
    # Remove IPv6 Tunnel Address
    if [ -n "${ifconfig_pool_remote_ip6}" ]; then
        /usr/bin/ddns-update del "${ifconfig_pool_remote_ip6}" "${dev}"
    fi
fi
exit ${jd_status}
