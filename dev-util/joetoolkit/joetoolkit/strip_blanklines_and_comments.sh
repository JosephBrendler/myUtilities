#!/bin/bash
#grep -v "#" $1 | while read line; do [ ! -z "${line}" ] && echo $line; done
grep -Ev '(^\s*$|^#)' "$1"
