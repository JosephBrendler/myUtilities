#!/bin/bash
# depends on dev-libs/openssl and app-admin/apg
apg -M LCNS -m 16 -c $(openssl rand 16)
