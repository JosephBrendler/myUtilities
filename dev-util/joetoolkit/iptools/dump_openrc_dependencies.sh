#!/bin/bash
source /usr/sbin/script_header_joetoo

service_list=(
  sysklogd
  stubby
  dnsmasq
  shorewall
  shorewall6
  net.br0
  net.eth0
)

for x in "${service_list[@]}"; do
  echo; echo $x; echo $(repeat '-' ${#x}); 
  echo -n "(ineed) ";  /etc/init.d/$x ineed; 
  echo -n "(iwant) ";  /etc/init.d/$x iwant;  
  echo -n "(iafter) "; /etc/init.d/$x iafter; 
  echo -n "(iuse) ";   /etc/init.d/$x iuse;
done
