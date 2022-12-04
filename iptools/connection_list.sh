#!/bin/bash
# connecton_list.sh
# joe brendler
# 10 Apr 16

#---[ local variables ]---------------------------
source /usr/local/sbin/script_header_brendlefly
BUILD=0.0.1
#target=/proc/net/ip_conntrack
target=/proc/net/nf_conntrack
array=('')

separator "connection_list-${BUILD}"
checkroot

#read count of connections and ip into array
while IFS=' ' read -a array
do
  # assign from array
  count=${array[0]};   ip=${array[1]}
  connector=" connections to "
  # start each output message with "[ nnn ] connections to ww.xx.yy.zz"
  msg="[ ${LBon}${count}${Boff} ]${connector}${BYon}${ip}${Boff}"
  # concatenate next line with look up the ip in whois database
  msg+="\n${LBon}$(whois ${ip} 2>/dev/null | grep Organization | cut -d':' -f2 | sed 's/^ *//' )${Boff}"
  # concatenate same line with geolocation of the ip; indent line(s) 6 spaces
  msg+=" [ $(geoiplookup ${ip} 2>/dev/null | \
        grep -v 'GeoIP Country Edition:' | grep -v 'GeoIP ASNum Edition:' | \
        sed 's/GeoIP City Edition, Rev 1: //' | \
        sed 's/^ *//' ) ]"
  # output the message
  message "${msg}"
     # read input from target file [/proc/net/nf_conntrack]; count number of connections to each unique dest ip
done <<< $(grep -v "sport=53" ${target} | cut -d'=' -f3 | cut -d' ' -f1 | sort | uniq -c | sort -bn | sed 's/^ *//')

