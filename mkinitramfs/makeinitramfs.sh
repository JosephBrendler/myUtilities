#!/bin/bash
# Joe Brendler  29 Dec 2012
#   rev 12 Sep 2014 - built in header with script functions

source /usr/local/sbin/script_header_joe_brendler
E_BADBOOT=68
BUILD="0.0.2 (20140912)"
INITRAMFS_DIR="/usr/src/initramfs"

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
  [ -f /boot/my-initramfs.cpio.gz ] && cp -v /boot/my-initramfs.cpio.gz /boot/my-initramfs.old.cpio.gz

  find . -print0 | cpio --null -ov --format=newc | gzip -9 > /boot/my-initramfs.cpio.gz
}

#---[ main script ]----------
separator "makeinitramfs $BUILD"

checkroot && check_boot && \
old_pwd=$PWD && cd "${INITRAMFS_DIR}" && make_initramfs && cd "${old_pwd}"
message "all done"
