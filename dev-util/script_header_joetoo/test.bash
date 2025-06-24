#!/bin/bash
#[ -z $1 ] && echo "please provide preface and/or title" && exit 1
#source ./script_header_joetoo
#script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo
#separator $@
#summarize_me
#sh_countdown 2

#message "now testing source ./script_header_joetoo_extended and run_sequence"
#message "this should WORK for a bash shell like this one"
# this should work for ash shell
#source ./script_header_joetoo_extended
#INTERACTIVE=$TRUE
#VERBOSE=$TRUE
#verbosity=5
#BUILD=0.1
#command_sequence=('echo "this"' 'echo "is line 2"' 'echo "and line 3"')
#starting_step=0
#stopping_step=${#command_sequence[@]}
#status_file=/root/test_status
#run_sequence $status_file
#echo

#message "now testing source resume run_sequence, non-interactive"
# this should work for ash shell
#source ./script_header_joetoo_extended
#INTERACTIVE=$FALSE
#echo


# this should work for ash shell
source ./script_header_joetoo
source ./script_header_joetoo_extended
script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo
cmdseq_statusfile=/root/cmdseq_status
VERBOSE=$TRUE
verbosity=5

validate_status_file $cmdseq_statusfile
varlist="PN bool.INTERACTIVE bool.VERBOSE verbosity BUILD starting_step stopping_step cmdseq_statusfile"
longest=$(get_longest ${varlist})
initialize_vars
PN=$(basename $0)
INTERACTIVE=$TRUE
VERBOSE=$TRUE
verbosity=5
BUILD=0.1
command_sequence=('echo "this"' 'echo "is line 2"' 'echo "and line 3"')
msg1_sequence=('echo "this"' 'echo "is line 2"' 'echo "and line 3"')
starting_step=0
stopping_step=${#command_sequence[@]}
status_file=/root/test_status

separator ${PN} "(test process_cmdline)"
process_cmdline $@
display_vars $longest ${varlist}
run_sequence $cmdseq_statusfile

echo


