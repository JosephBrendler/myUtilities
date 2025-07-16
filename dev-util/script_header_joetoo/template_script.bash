#!/bin/bash
# template script employing script_header_joetoo (extended)

# source headers
#script_header_installed_dir=./         ## only when testing, pre-ebuild
script_header_installed_dir=/usr/sbin   # this is where it should be installed
source ${script_header_installed_dir%/}/script_header_joetoo
# you need to assign BPN before sourcing script_header_joetoo_extended, which
#  uses ${BPN} to locate local custom conent employing its cli processing, etc --
#      /etc/${BPN}/local.useage
#      /etc/${BPN}/local.cmdline_arguments
#      /etc/${BPN}/local.cmdline_compound_arguments
# example:
# message_n "sourcing BPN ..."
# source /etc/template_script.bash/BPN ; right_status $?
#   where that file contains an assignment like:  BPN="template_script.bash"
source ${script_header_installed_dir%/}/script_header_joetoo_extended

# only needed for testing sources pending package build
#script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo

#-----[ variables ]------------------------------------------------------
cmdseq_statusfile=/root/cmdseq_status
VERBOSE=$TRUE
verbosity=5
PN=$(basename $0)

# BPN = PN here, but it could be different for several programs using common functions
# (e.g. dev-sbc/crossbuild-tools and its cb-mkenv, cb-mkimg, cb-mkdev tools all use
#  BPN="crossbuild-tools" so they can all use cli with the same cb-common-functions)
BPN=${PN}

FLAGGED=$FALSE
result=0

varlist=" PN BPN BUILD starting_step stopping_step cmdseq_statusfile"
varlist+=" BREAK bool.EXAMPLE bool.DEFAULTS"  ## dummy options set by local cmdline_argument modules
varlist+=" BREAK bool.INTERACTIVE bool.FLAGGED bool.VERBOSE verbosity"

hidden_varlist="result response answer "

command_sequence=('echo "this"' 'echo "is line 2"' 'echo "and line 3"')
msg1_sequence=('echo "this"' 'echo "is line 2"' 'echo "and line 3"')

#-----[ functions ]------------------------------------------------------

initialize_variables() {
    # use script_header_joetoo functions
    initialize_vars ${varlist}
    initialize_vars ${hidden_varlist}

    FLAGGED=$FALSE
    # assign initial values
    message_n "Assigning PN = $(basename $0) ..."
    PN=$(basename $0) ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    message_n "Assigning BPN = ${PN} ..."
    BPN=${PN} ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    message_n "Assigning INTERACTIVE = \$TRUE ..."
    INTERACTIVE=$TRUE ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    message_n "Assigning VERBOSE = \$TRUE ..."
    VERBOSE=$TRUE ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    message_n "Assigning verbosity = 3 ..."
    verbosity=3 ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    message_n "Assigning BUILD = 0.1 ..."
    BUILD=0.1 ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    message_n "Assigning starting_step = 0 ..."
    starting_step=0 ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    message_n "Assigning stopping_step = \${#command_sequence[@]} - 1 ..."
    stopping_step=$(( ${#command_sequence[@]} - 1 )) ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    message_n "Assigning cmdseq_statusfile = /root/test_status ..."
    cmdseq_statusfile=/root/test_status ; result=$? ; right_status $result
    [ ! $result -eq 0 ] && FLAGGED=$TRUE

    [ $FLAGGED ] && return 1 || return 0
}

display_configuration() {
    separator ${PN} "(display configuration)"
    # use script_header_joetoo functions
    longest=$(get_longest ${varlist})
    display_vars $longest ${varlist} || return 1
    return 0
}

sanity_check() {
    separator ${PN} "(sanity check)"
    # put some code here to catch dumb stuff like cmdline option assignments that should
    # be mutually exclusive
    [ ! $INTERACTIVE ] && [ $EXAMPLE ] && E_message "(demonstration) INTERACTIVE and EXAMPLE should NOT both be TRUE; quitting" && return 1
    return 0
}

#-----[ main script ]----------------------------------------------------
checkroot
separator ${PN} $(hostname)


# basic common approach -
# initialize variables (local function)
# validate_status_file  (script_header_joetoo_extended)
# process_cmdline (script_header_joetoo_extended)
# local validation, configuration, and variable assignment (local function(s))
# display_configuration so we can see what's what if insane (script_header_joetoo_extended)
# sanity_check (cb-common-functions)
# run_sequence (script_header_joetoo_extended)

# initialize variables and set default values
initialize_variables || die "Failed to initialize_variables"

validate_status_file $cmdseq_statusfile || die "Failed to validate_status_file"

# over-ride configuration with commandline input
separator ${PN} "(process_cmdline)"
process_cmdline $@  || die "Failed to process_cmdline"

display_configuration || die "Failed to display_configuration"

# sanity check configuration
sanity_check || die "Failed sanity_check"

# use script_header_joetoo_extended (bash) functions
run_sequence $cmdseq_statusfile || die "Failed to run_sequence"

message "${PN} Complete"
echo
