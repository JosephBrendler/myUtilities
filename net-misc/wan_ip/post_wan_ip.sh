#!/bin/bash
# post_wan_ip.sh (with get_wan_ip.sh) to Dropbox
# joe brendler -- 6 Dec 2016
# (post my wan ip address, so I can use it from remote locations to make a vpn connection)

source /etc/wan_ip/wan_ip.conf

# echo a short formatted date string (dd_hhmmss_mmmyyyy)
my_short_date() {
  month=$(date +%b); monthday=$(date +%d); year=$(date +%Y); timehack=$(date +%H%M%S);
  echo "${year}${month}${monthday}_${timehack}";
}

old_dir=$(pwd)
cd ${HOME_DIR}

WAN_IP=$( ${WAN_IP_GET_PROG} ) && \
echo "${WAN_IP} [$(my_short_date)]" > ${WAN_IP_DROPBOX_DIR%/}/${WAN_IP}
chown ${WAN_IP_USER}:${WAN_IP_USER} ${WAN_IP_DROPBOX_DIR%/}/${WAN_IP}

. /usr/sbin/loggit

cd ${old_dir}
