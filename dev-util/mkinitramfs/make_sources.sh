#!/bin/bash
# make_sources.sh (formerly mkinitramfs.sh) -- set up my custom initramfs
# Joe Brendler - 9 September 2014  (adopting new layout 6 Jan 2025)
#    for version history and "credits", see the accompanying "historical_notes" file

# --- Define local variables -----------------------------------

# the GLOBALS file identifies the BUILD, SOURCES_DIR (e.g. /usr/src/initramfs),
#   and the MAKE_DIR (parent dir of this script)
source GLOBALS
# subsititure below for testing only
#source GLOBALS.scratch_test

source "${SCRIPT_HEADER_DIR}/script_header_joetoo"
# script header will over-ride BUILD, but globals must be sourced 1st to get _DIRs
BUILD="${KERNEL_VERSION}-${DATE_STAMP}"
PN=$(basename "$0")

verbosity=2

# identify config file
[[ -f "${MAKE_DIR}/init.conf" ]] && CONF_DIR="${MAKE_DIR}"
[[ -f /etc/mkinitramfs/init.conf ]] && CONF_DIR="/etc/mkinitramfs"
[[ -f "${MAKE_DIR}/mkinitramfs.conf" ]] && MAKE_CONF_DIR="${MAKE_DIR}"
[[ -f /etc/mkinitramfs/mkinitramfs.conf ]] && MAKE_CONF_DIR="/etc/mkinitramfs"

# draw separator to indicate beginning of run
separator "${PN}-$BUILD" "(setup)"

# override (ROTATE and verbosity) variables with mkinitramfs.conf file
message_n "Sourcing mkinitramfs.conf ..."
source "${MAKE_CONF_DIR}/mkinitramfs.conf" ; right_status $?

# source the init_structure list
message_n "Sourcing init_structure variables ..."
source "${MAKE_DIR%/}/init_structure" ; right_status $?

#source ${MAKE_DIR}/dyn_executables_header
# initialize list of executables
executables=()
# initialize list of dependencies of executables
dependencies=()

#---[ functions ]-----------------------------------------------

# source functions in make_sources_functions_header
message_n "Sourcing functions in make_sources_functions_header ..."
source "${MAKE_DIR%/}/make_sources_functions_header" ; right_status $?

# source functions in common_bash_functions_header (load_list_ dump_executables)
message_n "Sourcing functions in common_bash_functions_header ..."
source "${MAKE_DIR%/}/common_bash_functions_header" ; right_status $?

# source functions in common_ash_functions_header (display_config, echo_long_string)
message_n "Sourcing functions in common_ash_functions_header ..."
source "${MAKE_DIR%/}/common_ash_functions_header" ; right_status $?

#---[ Main Script ]-------------------------------------------------------
# Create the required directory structure -- maintain the file
#   ${MAKE_DIR}/initramfs_dir_tree to tailor this
checkroot

# create displayable strings from arrays (just for show_config)
bins_str="${bins[@]}"
libs_str="${libs[@]}"
structure_str="${structure[@]}"
admin_files_str="${admin_files[@]}"
function_headers_src_str="${function_headers_src[@]}"
function_headers_dest_str="${function_headers_dest[@]}"
other_content_src_str="${other_content_src[@]}"
other_content_dest_str="${other_content_dest[@]}"
init_executables_str="${init_executables[@]}"
busybox_link_list_str="${busybox_link_list[@]}"
lvm_link_list_str="${lvm_link_list[@]}"
other_link_dir_str="${other_link_dir[@]}"
other_link_target_str="${other_link_target[@]}"
other_link_name_str="${other_link_name[@]}"

# display configuration (single word variables)
varlist="SOURCES_DIR MAKE_DIR MAKE_CONF_DIR BUILD config_file verbosity"
# display configuration (strings from arrays)
varlist+=" lv.bins_str lv.libs_str lv.structure_str lv.admin_files_str"
varlist+=" lv.function_headers_src_str lv.function_headers_dest_str"
varlist+=" lv.other_content_src_str lv.other_content_dest_str"
varlist+=" lv.init_executables_str BREAK"
varlist+=" lv.busybox_link_list_str lv.lvm_link_list_str"
varlist+=" lv.other_link_dir_str lv.other_link_target_str lv.other_link_name_str"
init_config_title="configuration"
#display_config $varlist
show_config

# build the initramfs directory sturcture
separator "${PN}-$BUILD" "(Build Directory Structure)"
# 20260126 - structure is now an array
build_structure "${structure[@]}"
build_other_devices

# initialize and load array of executables' full path names on this system
executables=()
separator "${PN}-$BUILD" "(Load list of executables)"
load_executables

# copy executables to the initramfs directory structure
separator "${PN}-$BUILD" "(Copy Executables)"
copy_executables

# copy other components to the initramfs directory structure
separator "${PN}-$BUILD" "(Copy Other Necessary Parts)"
copy_other_parts

# create symlinks in initramfs directory structure (for busybox, lvm, and others)
separator "${PN}-$BUILD" "(Create Symlinks)"
create_links

# copy dependencies to the initramfs directory structure (for executables)
separator "${PN}-$BUILD" "(Copy Dependent Libraries)"
copy_dependencies

# create the BUILD reference file to be used by the init script
separator "${PN}-$BUILD" "(Create the BUILD reference file)"
message_n "writing [BUILD=\"${BUILD}\"] to ${SOURCES_DIR}/BUILD ..."
echo "BUILD=\"${BUILD}\"" > "${SOURCES_DIR}/BUILD" ; right_status $?

# optionally display the resulting initramfs directory tree
d_do 'separator "${PN}-$BUILD" "(initramfs directory tree)"; tree "${SOURCES_DIR}"' 2
