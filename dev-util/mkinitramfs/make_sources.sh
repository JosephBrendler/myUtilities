#!/bin/bash
# make_sources.sh (formerly mkinitramfs.sh) -- set up my custom initramfs
# Joe Brendler - 9 September 2014  (adopting new layout 6 Jan 2025)
#    for version history and "credits", see the accompanying "historical_notes" file

# --- Define local variables -----------------------------------

# the GLOBALS file identifies the BUILD, SOURCES_DIR (e.g. /usr/src/initramfs),
#   and the MAKE_DIR (parent dir of this script)
source GLOBALS
source ${SCRIPT_HEADER_DIR}/script_header_joetoo
# script header will over-ride BUILD, but globals must be sourced 1st to get _DIRs
BUILD="${KERNEL_VERSION}-${DATE_STAMP}"

VERBOSE=$TRUE
#VERBOSE=$FALSE
verbosity=2

# identify config file
[[ -e ${MAKE_DIR}/init.conf ]] && CONF_DIR=${MAKE_DIR}
[[ -e /etc/mkinitramfs/init.conf ]] && CONF_DIR="/etc/mkinitramfs"
[[ -e ${MAKE_DIR}/mkinitramfs.conf ]] && MAKE_CONF_DIR=${MAKE_DIR}
[[ -e /etc/mkinitramfs/mkinitramfs.conf ]] && MAKE_CONF_DIR="/etc/mkinitramfs"

# draw separator to indicate beginning of run
separator "make_sources.sh setup"  "mkinitramfs-$BUILD"

# override (ROTATE and verbosity) variables with mkinitramfs.conf file
message_n "Sourcing mkinitramfs.conf ..."
source ${MAKE_CONF_DIR}/mkinitramfs.conf ; right_status $?

# source the init_structure list
message_n "Sourcing init_structure variables ..."
source ${MAKE_DIR%/}/init_structure ; right_status $?

#source ${MAKE_DIR}/dyn_executables_header
# initialize list of executables
executables=()
# initialize list of dependencies of executables
dependencies=()

#---[ functions ]-----------------------------------------------

# source functions in make_sources_functions_header
message_n "Sourcing functions in make_sources_functions_header ..."
source ${MAKE_DIR%/}/make_sources_functions_header ; right_status $?

# source functions in common_bash_functions_header (load_list_ dump_executables)
message_n "Sourcing functions in common_bash_functions_header ..."
source ${MAKE_DIR%/}/common_bash_functions_header ; right_status $?

# source functions in common_ash_functions_header (display_config, echo_long_string)
message_n "Sourcing functions in common_ash_functions_header ..."
source ${MAKE_DIR%/}/common_ash_functions_header ; right_status $?

#---[ Main Script ]-------------------------------------------------------
# Create the required directory structure -- maintain the file
#   ${MAKE_DIR}/initramfs_dir_tree to tailor this
checkroot

# display configuration
varlist="SOURCES_DIR MAKE_DIR MAKE_CONF_DIR VERBOSE verbosity \
bins libs admin_files init_executables"
init_config_title="configuration"
display_config $varlist

# build the initramfs directory sturcture
separator "Build Directory Structure"  "mkinitramfs-$BUILD"
build_structure $structure
build_other_devices

# initialize and load array of executables' full path names on this system
executables=()
separator "Load list of executables" "mkinitramfs-$BUILD"
load_executables

# copy executables to the initramfs directory structure
separator "Copy Executables"  "mkinitramfs-$BUILD"
copy_executables

# copy other components to the initramfs directory structure
separator "Copy Other Necessary Parts"  "mkinitramfs-$BUILD"
copy_other_parts

# create symlinks in initramfs directory structure (for busybox, lvm, and others)
separator "Create Symlinks"  "mkinitramfs-$BUILD"
create_links

# copy dependencies to the initramfs directory structure (for executables)
separator "Copy Dependent Libraries"  "mkinitramfs-$BUILD"
copy_dependencies

# create the BUILD reference file to be used by the init script
separator "Create the BUILD reference file"  "mkinitramfs-$BUILD"
message_n "writing [BUILD=\"${BUILD}\"] to ${SOURCES_DIR}/BUILD ..."
echo "BUILD=\"${BUILD}\"" > ${SOURCES_DIR}/BUILD ; right_status $?

# optionally display the resulting initramfs directory tree
if [[ $verbosity -gt 2 ]] ; then
  separator "initramfs directory tree" "mkinitramfs-$BUILD"
  tree ${SOURCES_DIR}
fi
