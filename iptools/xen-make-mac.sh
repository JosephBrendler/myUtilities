#!/bin/bash
echo -n "xen (00:16:3e) mac:  "
perl -e 'printf "00:16:3e:%02X:%02X:%02X\n", rand 0xFF, rand 0xFF, rand 0xFF'
echo
echo -n "totally random mac:  "
perl -e 'printf "%02X:%02X:%02X:%02X:%02X:%02X\n", rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF'
