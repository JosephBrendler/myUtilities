#!/bin/bash
# rollback_initramfs
# joe Brendler 29 Dec 2024

# the GLOBALS file identifies the BUILD, SOURCES_DIR (e.g. /usr/src/initramfs),
#   and the MAKE_DIR (parent dir of this script)
source GLOBALS
source "${SCRIPT_HEADER_DIR}/script_header_joetoo"
# script header will over-ride BUILD, but globals must be sourced 1st to get _DIRs
BUILD="${KERNEL_VERSION}-${DATE_STAMP}"

verbosity=2

# identify config files
[[ -e "${MAKE_DIR}/init.conf" ]] && CONF_DIR="${MAKE_DIR}"
[[ -e /etc/mkinitramfs/init.conf ]] && CONF_DIR="/etc/mkinitramfs"
[[ -e "${MAKE_DIR}/mkinitramfs.conf" ]] && MAKE_CONF_DIR="${MAKE_DIR}"
[[ -e /etc/mkinitramfs/mkinitramfs.conf ]] && MAKE_CONF_DIR="/etc/mkinitramfs"

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

#-----[ functions ]-----------------------------------------------------------------------

identify_current_targets() {
  # if any exist, identify the current targets of links (latest, working, safe)
  local _ict_initrds=() _ict_link
  # find links to initramfs files in /boot named initramfs* and
  # prepend the file path (%p) with Timestamp (%Ts), tab (\t), delimit with newline (\n) (for sort)
  # then sort the results, drop the timestamp, keeping the filename
  # finally translate newlines into null characters and read into null delimited array
  readarray -d '' _ict_initrds < <(find /boot/ -iname 'initramfs*' -type l -printf '%Ts\t%p\n'| sort -n | cut -f2 | tr '\n' '\0')
  for _ict_link in "${_ict_initrds[@]}"; do
    linkname=$(basename "$_ict_link")
    target=$(readlink "$_ict_link")
    d_message "  linkname: [${LBon}${linkname}${Boff}], target: [${BGon}${target}${Boff}]" 1
    case "${linkname}" in
      *"latest" ) latest="${target}";;
      *"working" ) working="${target}";;
      *"safe" ) safe="${target}";;
      * ) echo Error;;
    esac
  done
}

makelink() {
  # create a symbolic link linkname $2 --> target $1
  target="$1" linkname="$2"
  message_n "creating link ${LBon}${linkname}${Boff} --> ${BGon}${target}${Boff} ..."
  ln -snf "${target}" "${linkname}"
  right_status $?
}

#-----[ main script ]---------------------------------------------------------------------
checkroot
separator "rollback_initramfs-${BUILD}"

# move to /boot
message_n "saving current directory name; cd to /boot/..."
old_dir=$(pwd) && cd /boot/
right_status $?

message "Identifying current link targets ..."
identify_current_targets

# delete the current latest
if [ -f "${latest}" ]; then
  message_n "removing current latest [${BRon}${latest}${Boff}]"
  rm "${latest}" ; right_status $?
fi

# rollback the remaining initramfs
[ -f "${working}" ] && makelink "${working}" "initramfs.latest"
[ -f "${safe}" ] && makelink "${safe}" "initramfs.working"

# remove the obsolete link for "safe"
[ -L initramfs.safe ] && message_n "removing obsolete link [${BRon}initramfs.safe${Boff}]" && \
  ( rm initramfs.safe ; right_status $? )

message_n "returning to ${old_dir}..."
cd "${old_dir}"
right_status $?
