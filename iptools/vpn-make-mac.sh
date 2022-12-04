#!/bin/bash
perl -e 'printf "00:11:22:%02X:%02X:%02X\n", rand 0xFF, rand 0xFF, rand 0xFF'
