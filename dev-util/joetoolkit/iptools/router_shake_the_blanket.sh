#!/bin/bash
source /usr/sbin/script_header_joetoo

#-----[ variables ]-----------------------------------------------------------------

PN=$(basename $0)

key_router_services=(
  shorewall
  shorewall6
  dnsmasq
  radvd
  stubby
  samba
  cronie
  chronyd
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
checkroute
separator "$(hostname)" "$PN"
shake-the-blanket

rc-status

message "${BGon}Done${Boff}"
