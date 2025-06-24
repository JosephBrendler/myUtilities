#!/bin/ash
[ -z $1 ] && echo "please provide preface and/or title" && exit 1
source ./script_header_joetoo
script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo
separator $@
summarize_me

message "now testing source ./script_header_joetoo_extended and run_sequence"
message "this should FAIL for ash shell like this one"
# this should fail for ash shell
source ./script_header_joetoo_extended
command_sequence=('echo "this"' 'echo "is line 2"' 'echo "and line 3"')
status_file=/root/test_status
run_sequence $status_file

