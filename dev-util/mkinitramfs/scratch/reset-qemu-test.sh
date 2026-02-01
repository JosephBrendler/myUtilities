#!/bin/bash

source /usr/sbin/script_header_joetoo

base="/home/joe/myUtilities/dev-util/mkinitramfs/scratch"
message_n "moving to ${base}"
cd "${base}"
handle_result $? "$PWD" "$PWD"

[ -d initramfs ] && rm -r "initramfs"
find ./boot -type f -delete
