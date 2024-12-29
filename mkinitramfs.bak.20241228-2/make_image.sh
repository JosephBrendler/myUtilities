#!/bin/bash
# Joe Brendler  29 Dec 2012
#   for version history and "credits", see the accompanying "historical_notes" file
#   as ov version 5.2, this script is provided separately, in case the user does
#   NOT want to use it, but rather prefers to only make the sources and have the
#   initramfs compiled into the kernel

# this script must be run from the directory in which these scripts reside (so that
#   "source GLOBALS" makes sense.  GLOBALS instantiates all the variables needed
#   for directory-references.  This script must also be run AFTER the make_sources.sh
#   script is run, because the latter generates the BUILD file in ${SOURCES_DIR} that
#   will be sourced here to instantiate the BUILD variable
source GLOBALS
# source my usual functions and formatting "shortcuts" (must be run from the MAKE_DIR)
source ${SCRIPT_HEADER_DIR}/script_header_brendlefly
source ${SOURCES_DIR}/BUILD

VERBOSE=$TRUE
verbosity=1

# identify config files
[[ -e ${MAKE_DIR}/init.conf ]] && CONF_DIR=${MAKE_DIR}
[[ -e /etc/mkinitramfs/init.conf ]] && CONF_DIR="/etc/mkinitramfs"
[[ -e ${MAKE_DIR}/mkinitramfs.conf ]] && MAKE_CONF_DIR=${MAKE_DIR}
[[ -e /etc/mkinitramfs/mkinitramfs.conf ]] && MAKE_CONF_DIR="/etc/mkinitramfs"

# override (ROTATE and verbosity) variables with mkinitramfs.conf file
source ${MAKE_CONF_DIR}/mkinitramfs.conf

d_message "make_image.sh Debug - dump config" 2
d_message "BUILD: [ ${BUILD} ]" 2
d_message "MAKE_DIR: [ ${MAKE_DIR} ]" 2
d_message "SOURCES_DIR: [ ${SOURCES_DIR} ]" 2

make_initramfs()
{
  # if target file already exists, archive it to *.old
  [ -f /boot/initramfs-${BUILD} ] && cp -v /boot/initramfs-${BUILD} /boot/initramfs-${BUILD}.old

  find . -print0 | cpio --null -ov --format=newc | gzip -9 > /boot/initramfs-${BUILD}
}

#---[ main script ]----------
separator "Make initramfs Image"  "makeinitramfs-$BUILD"

# must be run by root with boot mounted already
# go to sources dir, and run function above to create initramfs image file
checkroot && checkboot && \
old_pwd=$PWD && cd "${SOURCES_DIR}" && make_initramfs && cd "${old_pwd}"
d_message "all done" 1
