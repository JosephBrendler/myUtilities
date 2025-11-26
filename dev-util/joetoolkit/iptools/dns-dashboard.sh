#!/bin/bash
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_unicode

#-----[ variables ]----------------------------------------------------------------

LEASES_FILE="/var/lib/misc/dnsmasq.leases"

#-----[ functions ]----------------------------------------------------------------
timestamp ()
{
    echo "$(date '+%Y%m%d-%H:%M:%S')"
}


while [ true ] ; do
  clear;
  message "${BYon}#$(repeat '-' 64)${Boff}"
  message "${LBon}# /etc/hosts.d/20_openVPN_clients as of $(timestamp)${Boff}"
  message "${BYon}#$(repeat '-' 64)${Boff}"
  cat /etc/hosts.d/20_openVPN_clients;
  sleep 5;
  clear;
  message "${BYon}#$(repeat '-' 89)${Boff}"
  message "${LBon}## /etc/hosts.d/30_ddns_clients as of $(timestamp)${Boff}"
  message "${BYon}#$(repeat '-' 89)${Boff}"
  cat /etc/hosts.d/30_ddns_clients;
  sleep 5;
  clear;
  message "${BYon}#$(repeat '-' 66)${Boff}"
  message "${LBon}## /var/lib/misc/dnsmasq.leases as of $(timestamp)${Boff}"
  message "${BYon}#$(repeat '-' 66)${Boff}"
  message "(DUID and TIMESTAMP also available in /var/lib/misc/dnsmasq.leases)"
#  cat /var/lib/misc/dnsmasq.leases;
  # space-delimitted fields: ignore timestamp, MAC (17), IP (15), HOSTNAME (17), DUID (the rest)
  while read -r TIMESTAMP MAC_ADDR IP_ADDR HOSTNAME DUID_REST; do
    # Skip empty lines or lines that don't look like a lease entry
    [[ -z "$MAC_ADDR" ]] && continue
    # DUID_REST may contain spaces, though usually it's just the DUID
    # The read command captures everything from the 5th field onward into DUID_REST.
    # This assignment quotes it, to avoid word-splitting, or assigns "N/A" if it is empty
    DUID_VAL="${DUID_REST:-N/A}"
    # Use printf for fixed-width, columnar output
#    printf "%-22s %-18s %-20s %s\n" \
#        "$MAC_ADDR" \
#        "$IP_ADDR" \
#        "$HOSTNAME" \
#        "$DUID_VAL"
    printf "%-22s %-18s %s\n" \
        "$IP_ADDR" \
        "$HOSTNAME" \
        "$MAC_ADDR"

  done <<<$(sort -k4 "$LEASES_FILE")
  sleep 5;

done # while true
