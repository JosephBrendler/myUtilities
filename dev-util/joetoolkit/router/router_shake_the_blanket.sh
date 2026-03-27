#!/bin/bash
source /usr/sbin/script_header_joetoo

#-----[ variables ]-----------------------------------------------------------------

PN=${0##*/}   # like =$(basename $0) but w/o subshell and function call

key_router_services=(
  net.eth0
  net.br0
  ipset
  ulogd
  shorewall
  shorewall6
  dnsmasq
  radvd
  stubby
  hostapd
  haveged
  conntrackd
  samba
  cronie
  chronyd
  node_exporter
  prometheus
  systat
  grafana
)

#-----[ functions ]-----------------------------------------------------------------

shake-the-blanket() {
for x in "${key_router_services[@]}"; do
  /etc/init.d/$x restart;
done
}

#-----[ main script ]---------------------------------------------------------------
checkroot
separator "$(hostname)" "$PN"
shake-the-blanket

rc-status

j_msg -${notice} -p "${BGon}Done${Boff}"
