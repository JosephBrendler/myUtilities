#!/bin/bash
source /usr/sbin/script_header_joetoo
wait=1

[[ $# -gt 1 ]] && j_msg -${err} "too many arguments (one <interface> allowed)" && exit 1
interface=${1:-eth0}

# check if interface exists
if [ ! -d "/sys/class/net/$interface" ]; then
  j_msg -${err} "interface [$interface] does not exist"
  exit 1
fi

# check if interface is administratively up
if ip link show "$interface" up >/dev/null 2>&1; then
    j_msg -${info} -m "$interface is valid and UP"
else
    j_msg -${err} "$interface is invalid or administratively DOWN"
    exit 1
fi


CLR
CUP 2 2
j_msg -${notice} -p "Checking carrier status ..."

CUP 5 10
j_msg -mp -n "Carrier: "
SCP

status="down"
while [[ $TRUE ]] && [[ ! "$status" == "up" ]]
do
  j_msg -mp -n "          "; RCP

  # check if interface has a physical link
  if [ -f "/sys/class/net/$interface/carrier" ] && [ "$(cat /sys/class/net/$interface/carrier)" -eq 1 ]; then
    link="${BGon}yes${Boff}"
  else
    link="${BRon}no${Boff}"
  fi

  # check the count of transmit carrier signal losses on interace
  carrier_losses=$(cat /proc/self/net/dev | grep -i ${interface} | awk '{print $15}')
  if [ "$carrier_losses" -eq 0 ]; then
    carrier_losses="${BGon}$carrier_losses${Boff}"
  else
    carrier_losses="${BYon}$carrier_losses${Boff}"
  fi

  # check the operational status of interface
  if [ -f "/sys/class/net/$interface/operstate" ]; then
    status=$(cat /sys/class/net/$interface/operstate)
    case "$status" in
      up) clr_status="${BGon}$status${Boff}" ;;
      *down|notpresent) clr_status="${BRon}$status${Boff}" ;;
      testing|dormant) clr_status="${BYon}$status${Boff}" ;;
    esac
  fi
  j_msg -mp -n "link: [$link]  status: [$clr_status]  carrier losses: [$carrier_losses]"
  RCP
  sleep ${wait}
done
CUD 3 ; printf '\r'
j_msg -${notice} -p "done"
