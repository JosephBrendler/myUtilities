#!/bin/bash
# Joe Brendler, 30 Jan 19
#
# Assign ssh password and use to execute remote command on host "router"
# (edit for use)
#
p="routerpassword"
ip="x.x.x.x"
user="routeradminusername"
opts="StrictHostKeyChecking=no"
rcmd="grep -i externalipaddress /mnt/log/operations.log.0"
#
sshpass -p"${p}" ssh -o "${opts}" ${user}@${ip} "${rcmd}" \
   | cut -d',' -f4 | uniq
