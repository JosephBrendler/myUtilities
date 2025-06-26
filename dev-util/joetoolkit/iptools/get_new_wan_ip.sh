#!/bin/bash
# Joe Brendler, 30 Jan 19
#
# I used to do this by hacking into my router and digging out the wan ip
# version 1 (2014) used python request, supplying username and password for
#   the router admin page (I don't like storing pwds,
#   and routers evolved to defeat this with script-based login pages)
#
# version 2 (2019) used shhpass --
#   sshpass -p"${p}" ssh -o "${opts}" ${user}@${ip} "${rcmd}" | cut -d',' -f4 | uniq
#
# version 3 (2023) exploits the trick that the speedtest utility reports
#   the local router's wan ip
#
# I've identified two ways to parse the results
# (1) speedtest --csv | cut -d',' -f11
# (2) speedtest --json | jq -r '.client.ip'
#
# method 2 relies on app-misc/jq as well as
#                    net-analyzer/speedtest-cli
#  but it should be more stable
speedtest --json | jq -r '.client.ip'
