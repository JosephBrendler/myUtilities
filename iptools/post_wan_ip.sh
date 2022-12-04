#!/bin/bash
# post_wan_ip.sh (with get_wan_ip.sh)
# joe brendler -- 6 Dec 2016
# (post my wan ip address, so I can use it from remote locations to make a vpn connection)

# echo a short formatted date string (dd_hhmmss_mmmyyyy)
my_short_date() {
  month=$(date +%b); monthday=$(date +%d); year=$(date +%Y); timehack=$(date +%H%M%S);
#  echo "${monthday}_${timehack}_${month}${year}";
  echo "${year}${month}${monthday}_${timehack}";
}

old_dir=$(pwd)
cd /home/joe

WAN_IP=$(/root/bin/get_wan_ip.sh) && \
#echo ${WAN_IP} > /home/joe/Dropbox/wan_ip/wan_ip.txt && \
#echo ${WAN_IP} > /home/joe/Dropbox/wan_ip/wan_ip-${WAN_IP}-$(my_short_date).txt
echo "${WAN_IP} [$(my_short_date)]" > /home/joe/Dropbox/wan_ip/${WAN_IP}
chown joe:joe /home/joe/Dropbox/wan_ip/${WAN_IP}

. /root/bin/loggit

cd ${old_dir}
