#!/bin/bash
# rollback_initramfs
# joe Brendler 29 Dec 2024

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

# identify config files
[[ -f "${MAKE_DIR}/init.conf" ]] && CONF_DIR="${MAKE_DIR}"
[[ -f /etc/mkinitramfs/init.conf ]] && CONF_DIR="/etc/mkinitramfs"
[[ -f "${MAKE_DIR}/mkinitramfs.conf" ]] && MAKE_CONF_DIR="${MAKE_DIR}"
[[ -f /etc/mkinitramfs/mkinitramfs.conf ]] && MAKE_CONF_DIR="/etc/mkinitramfs"

# override (ROTATE and verbosity) variables with mkinitramfs.conf file
source "${MAKE_CONF_DIR}/mkinitramfs.conf"

#-----[ initialize script-global variables ]-------------------------------------------------------
newinitramfs=""
newtimestamp=""
linkname=""
target=""
latest=""
working=""
safe=""

img_ROOT="/"
# subsititure below for testing only
#img_ROOT="${MAKE_DIR%/}/scratch/"

#-----[ functions ]-----------------------------------------------------------------------

identify_current_targets() {
  # if any exist, identify the current targets of links (latest, working, safe)

  # first collect the link names
  # for maintainability build the find command arguments in a readable array
  local find_cmd link_path
  find_cmd=( find .         # search current directory
    -maxdepth 1                   # only, no subdirectories
    -iname 'initramfs*'           # for filenames matching "initramfs*"
    -type l                       # (** symlinks only **)
    -printf '%Ts\t%p\0' )         # prefix with a timestamp for sorting, and delimit with null char for safe handling
  # execute the array using the "@" expansion (quoted to preserve arguments)
  readarray -d '' initramfs_list < <(
    "${find_cmd[@]}" |            # see above
    sort -n -z |                  # sort numeric ascending, zero-terminated (on timestamps)
    cut -z -f2-                   # drop timestamp (order is oldest to newest)
  )                               #  -- says "end of options"
  # check for empty element at end or array (from final \0 deimitter (trim it)
  [[ ${#initramfs_list[@]} -gt 0 && -z "${initramfs_list[-1]}" ]] && unset "initramfs_list[-1]"

  # now get the target for each link
  if [[ ${#initramfs_list[@]} -gt 0 ]]; then
    for link_path in "${initramfs_list[@]}"; do
      linkname=$(basename "$link_path")
      target=$(readlink "$link_path")
      d_message "linkname: [${LBon}${linkname}${Boff}], target: [${BGon}${target}${Boff}]" 1
      case "$linkname" in
        *"latest" ) latest="$target";;
        *"working" ) working="$target";;
        *"safe" ) safe="$target";;
        * ) die "invalid link name [$linkname]" ;;
      esac
    done
  fi
}

makelink() {
  # create a symbolic link linkname $2 --> target $1
  local target="${1##*/}"   # equiv. to $(basename $1) but w/o forked subshell; ##*/ is strip longest match thru /
  linkname="$2"
  message_n "creating link ${LBon}${linkname}${Boff} --> ${BGon}${target}${Boff} ..."
  ln -snf "$target" "$linkname"
  handle_result $? "linked" '' || die "failed to create link"
}

#-----[ main script ]---------------------------------------------------------------------
checkroot
separator "${PN}-${BUILD}" "($(hostname))"

# move to /boot
message_n "saving current directory name; cd to /boot/..."
old_dir=$(pwd) && cd "${img_ROOT%/}/boot/"
right_status $?

message "Identifying current link targets ..."
identify_current_targets

# delete the current latest
if [ ! -z "${latest}" ]; then
  message_n "removing current latest [${BRon}${latest}${Boff}]"
  rm -f "${latest}" ; handle_result $? "removed" ''  # -f keeps shell from complaining if "$safe" was already deleted
fi

# rollback the remaining initramfs
[ ! -z "${working}" ] && makelink "${working}" "initramfs.latest"
[ ! -z "${safe}" ] && makelink "${safe}" "initramfs.working"

# remove the obsolete link for "safe"
[ -L initramfs.safe ] && { message_n "removing obsolete link [${BRon}initramfs.safe${Boff}]";
  rm -f initramfs.safe ; handle_result $? "removed" '' ; } # -f keeps shell from complaining if "$safe" was already deleted

message_n "returning to ${old_dir}..."
cd "${old_dir}"
right_status $?
