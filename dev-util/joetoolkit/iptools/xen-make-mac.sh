#!/bin/bash
j_msg -p -n "xen (00:16:3e) mac:  "
perl -e 'printf "00:16:3e:%02X:%02X:%02X\n", rand 0xFF, rand 0xFF, rand 0xFF'
j_msg -p  -n "\ntotally random mac:  "
perl -e 'printf "%02X:%02X:%02X:%02X:%02X:%02X\n", rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF'
