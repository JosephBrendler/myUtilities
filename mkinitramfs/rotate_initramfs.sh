#!/bin/bash
# rotate_initramfs
# joe Brendler 20 Nov 2020

# the GLOBALS file identifies the BUILD, SOURCES_DIR (e.g. /usr/src/initramfs),
#   and the MAKE_DIR (parent dir of this script)
source GLOBALS
source ${SCRIPT_HEADER_DIR}/script_header_brendlefly
# script header will over-ride BUILD, but globals must be sourced 1st to get _DIRs
BUILD="${KERNEL_VERSION}-${DATE_STAMP}"

#source /usr/local/sbin/script_header_brendlefly
#BUILD="0.0.0a"

VERBOSE=$TRUE
verbosity=2

#-----[ initialize local variables ]-------------------------------------------------------
newinitramfs=""
newtimestamp=""
linkname=""
target=""
latest=""
working=""
safe=""

#-----[ functions ]-----------------------------------------------------------------------
identify_new_initramfs() {
  # identify new initramfs
  #   there should only be one, but examine all and overwrite variable to operate only on the last
  while read line
  do
    newinitramfs="${line}"
    d_message "newinitramfs: [${newinitramfs}]" 1
  done <<< $(find . -iname 'initramfs-*' -type f -printf '%Ts\t%p\n' | sort -n | cut -f2)

#  newtimestamp=$(echo ${newinitramfs} | cut -d'-' -f4)
  newtimestamp="${newinitramfs##*-}"
  d_echo
  d_message "${BYon}newinitramfs: [${Boff}${newinitramfs}${BYon}]${Boff}" 1
  d_message "${BYon}newtimestamp: [${Boff}${newtimestamp}${BYon}]${Boff}" 1
  d_echo
}

identify_current_targets() {
  # if any exist, identify the current targets of links (latest, working, safe)
  if [ $(find . -iname 'initramfs*' -type l -printf '%Ts\t%p\n' | sort -n | cut -f2 ) ]
  then
    while read line
    do
      linkname=$(basename $(echo $line | cut -d' ' -f1 | sed 's/://'))
      target="${line##*link\ to\ }"
      d_message "linkname: [${LBon}${linkname}${Boff}], target: [${BGon}${target}${Boff}]" 1
      case $(echo ${linkname} | cut -d'.' -f2) in
        "latest" ) latest="${target}";;
        "working" ) working="${target}";;
        "safe" ) safe="${target}";;
        * ) echo Error;;
      esac
    done <<< $(find . -iname 'initramfs*' -type l -printf '%Ts\t%p\n' | sort -n | cut -f2 | xargs file)
  fi
}

makelink() {
  # create a symbolic link linkname $2 --> target $1
  local target="$1" linkname="$2"
  message_n "creating link ${LBon}${linkname}${Boff} --> ${BGon}${target}${Boff} ..."
  ln -snf ${target} ${linkname}
  right_status $?
}

#-----[ main script ]---------------------------------------------------------------------
checkroot
separator "rotate_initramfs-${BUILD}"

# move to /boot
message_n "saving current directory name; cd to /boot/..."
old_dir=$(pwd) && cd /boot/
right_status $?

identify_new_initramfs
identify_current_targets

# rename new initramfs file in .working. format
message_n "renaming ${BYon}${newinitramfs}${BBon} initramfs.working.${newtimestamp}${Boff} ..."
mv ${newinitramfs} initramfs.working.${newtimestamp}
right_status $?
# reassign newinitramfs variable to the new name
newinitramfs="initramfs.working.${newtimestamp}"

# put the newest initramfs in rotation and rotate older ones if they exist
makelink ${newinitramfs} "initramfs.latest"
[ -f "${latest}" ] && makelink ${latest} "initramfs.working"
[ -f "${working}" ] && makelink ${working} "initramfs.safe"

# delete the oldest
[ -f "${safe}" ] && \message_n "removing oldest [${BRon}${safe}${Boff}]" && \
  ( rm ${safe} ; right_status $? )

message_n "returning to ${old_dir}..."
cd ${old_dir}
right_status $?

