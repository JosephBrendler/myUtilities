#!/bin/bash
# Joe Brendler  29 Dec 2012
#   for version history and "credits", see the accompanying "historical_notes" file

# the GLOBALS file identifies the BUILD, SOURCES_DIR (e.g. /usr/src/initramfs), and the MAKE_DIR (parent dir of this script)
source GLOBALS
# source my usual functions and formatting "shortcuts"
source ${MAKE_DIR}/script_header_joe_brendler

E_BADBOOT=68

check_boot()
{
  # check to see if the /boot partition is properly mounted (look for grub)
  if [ -d "/boot/grub" ]
  then
    return 0
  else
    echo -e "${BRon}Boot partition not properly mounted.${Boff}"
    return $E_BADBOOT
  fi
}

make_initramfs()
{
  # if target file already exists, archive it to *.old
  [ -f /boot/initramfs-${BUILD} ] && cp -v /boot/initramfs-${BUILD} /boot/initramfs-${BUILD}.old

  find . -print0 | cpio --null -ov --format=newc | gzip -9 > /boot/initramfs-${BUILD}
}

#---[ main script ]----------
separator "makeinitramfs $BUILD"

checkroot && check_boot && \
old_pwd=$PWD && cd "${SOURCES_DIR}" && make_initramfs && cd "${old_pwd}"
message "all done"
