#!/bin/bash
# make_sources.sh (formerly mkinitramfs.sh) -- set up my custom initramfs
# Joe Brendler - 9 September 2014
#    for version history and "credits", see the accompanying "historical_notes" file

# --- Define local variables -----------------------------------

# the GLOBALS file identifies the BUILD, SOURCES_DIR (e.g. /usr/src/initramfs), and the MAKE_DIR (parent dir of this script)
source GLOBALS
source ${SCRIPT_HEADER_DIR}/script_header_brendlefly
# script header will over-ride BUILD, but globals must be sourced 1st to get _DIRs
BUILD="${KERNEL_VERSION}-${DATE_STAMP}"

# Error messages used by script
E_NOLVM="You need to install lvm first."
E_NOCRYPT="You need to install cryptsetup first."

OK_MSG="${BBon}[${BGon} Ok ${BBon}]${Boff}"
OK_MSG_LEN=$(( ${#OK_MSG} - $(( ${#BBon} + ${#BGon} + ${#BBon} + ${#Boff} )) ))
FAIL_MSG="${BBon}[${BRon}Fail${BBon}]${Boff}"
FAIL_MSG_LEN=$(( ${#FAIL_MSG} - $(( ${#BBon} + ${#BGon} + ${#BBon} + ${#Boff} )) ))
NA_MSG="${BBon}[${BYon} NA ${BBon}]${Boff}"
RESULT_MSG_LEN=$OK_MSG_LEN

tmpfile="./temporary_file"
tmpfile2="./temporary_file2"

# /bin: define dynamic and non-dynamic executables to be included in /bin /sbin and /usr/bin
bin_dyn_executables="busybox kmod udevadm lsblk"
bin_non_dyn_executables=""
# /sbin: note: included findfs here explicitly rather than use busybox's own
sbin_dyn_executables="blkid cryptsetup findfs e2fsck lvm"
sbin_non_dyn_executables="fsadm lvmconf lvmdump vgimportclone"
# /usr/bin: note: for the moment, I'm only getting shred...
usr_bin_dyn_executables="shred"
usr_bin_non_dyn_executables=""
# note: the following required executables are NOT dynamic -- no other libs needed for them:
#   /bin/busybox (update 16 Dec 16 -- removed "static" USE flag, busybox is now dynamic
#   /sbin/fbcondecor_helper
#   /sbin/fsadm
#   /sbin/lvmconf
#   /sbin/lvmdump
#   /sbin/vgimportclone

config_files="init.conf README GLOBALS"

DEBUG="false"
#DEBUG="true"
DEBUG2="false"
#DEBUG2="true"
DEBUG_LIB_COPY="false"
#DEBUG_LIB_COPY="true"
DEBUG_LIB_COPY2="false"
#DEBUG_LIB_COPY2="true"


#---[ functions ]-----------------------------------------------

display_config()
{
  message "SOURCES_DIR: "${SOURCES_DIR}
  message "MAKE_DIR: "${MAKE_DIR}
}

calculate_termwidth()
{
  termwidth=$(stty size | sed 's/[0-9]* *//')
}

check_for_parts()
{
  PARTSTRING=""
  calculate_termwidth
  #look for lvm and cryptsetup, and if not found, ask if user wants to install them
  msg="${BGon}*${Boff} Finding lvm..."
  msg_len=$(( ${#msg} - $(( ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  [ ! -e /sbin/lvm ] && PARTSTRING=${PARTSTRING}" sys-fs/lvm2" && \
    result="${FAIL_MSG}" || result="${OK_MSG}"
  print_result $msg_len "$result"

  msg="${BGon}*${Boff} Finding cryptsetup..."
  msg_len=$(( ${#msg} - $(( ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  [ ! -e /sbin/cryptsetup ] && PARTSTRING=${PARTSTRING}" sys-fs/cryptsetup" && \
    result="${FAIL_MSG}" || result="${OK_MSG}"
  print_result $msg_len "$result"

  # if splash is requested, check for it
  if [ "${init_splash}" == "yes" ]
  then
    msg="${BGon}*${Boff} Finding splashutils..."
    msg_len=$(( ${#msg} - $(( ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
    print_pending_op_msg "$msg"
    [ ! -e /sbin/fbcondecor_helper ] && PARTSTRING=${PARTSTRING}" media-gfx/splashutils" && \
      result="${FAIL_MSG}" || result="${OK_MSG}"
  else
    msg="${BGon}*${Boff} Skipping check for splashutils... (not requested)"
    msg_len=$(( ${#msg} - $(( ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  fi
  print_result $msg_len "$result"

  # if missing parts are identified, confirm user wants to emerge them, the do so
  ans="z"
  if [ ! -z "${PARTSTRING}" ]
  then
    while [ ! -z "$ans" ] && [ ! $(echo `expr index $ans [YyNn]`) -gt "0" ]
    do
      echo -e "${BRon}*${BYon} Necessary components appear to be missing [ ${BRon}${PARTSTRING} ${BYon}].${Boff}"
      echo -en "${BRon}*${BYon} Do you want to install them? (Y/n) : ${Boff}"
      read ans
    done
    case $ans in
      ""   ) emerge -av ${PARTSTRING} ;;                 # emerge missing parts
      [Yy] ) emerge -av ${PARTSTRING} ;;                 #   "      "       "
      [Nn] ) : message "Done" ; exit ;;                  # do nothing, exit
      *    ) E_message "failed to get answer"; exit ;;   # error msg and exit
    esac
  else
    :
  fi
}


  # note: included findfs here explicitly rather than use busybox's own
  # note: for the moment, I'm only getting shred from /usr/bin,


copy_parts()
{
  calculate_termwidth
  #copy /bin executable parts
  message "Copying necessary executable files..."
  for i in ${bin_dyn_executables} ${bin_non_dyn_executables}
  do
    copy_one_part /bin/$i ${SOURCES_DIR}/bin/
  done
  # /sbin
  for i in ${sbin_dyn_executables} ${sbin_non_dyn_executables}
  do
    copy_one_part /sbin/$i ${SOURCES_DIR}/sbin/
  done
  # /usr/bin
  for i in ${usr_bin_dyn_executables} ${usr_bin_non_dyn_executables}
  do
    copy_one_part /usr/bin/$i ${SOURCES_DIR}/usr/bin/
  done

  if [ "${init_splash}" == "yes" ]
  then
    copy_one_part /sbin/fbcondecor_helper ${SOURCES_DIR}/sbin/
  else
    message "Skipping copy for /sbin/fbcondecor_helper... (splash not requested)"
  fi
  copy_one_part ./init ${SOURCES_DIR}/

  # copy config files
  message "Copying necessary configuration files..."
  for i in $config_files
  do
    copy_one_part ${MAKE_DIR}/$i ${SOURCES_DIR}/
  done

  # copy other required content from ...
  message "Copying other required content ..."
  copy_one_part /usr/local/sbin/script_header_brendlefly ${SOURCES_DIR}/
  copy_one_part /etc/lvm/lvm.conf ${SOURCES_DIR}/etc/lvm/
  copy_one_part ./etc/modules ${SOURCES_DIR}/etc/
  if [ "${init_splash}" == "yes" ]
  then
    copy_one_part ${MAKE_DIR}/etc/initrd.splash ${SOURCES_DIR}/etc/
    copy_one_part ${MAKE_DIR}/etc/splash ${SOURCES_DIR}/etc/
  else
    message "Skipping copy for splash files in /etc/ ... (splash not requested)"
  fi

}

copy_one_part()
{
  msg="${BGon}*${Boff} Copying [ $1 ] to [ $2 ]..."
  msg_len=$(( ${#msg} - $(( ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  [ "$DEBUG" == "true" ] && echo "copy one part about to execute: cp -a $1 $2"
  print_pending_op_msg "$msg"
  if [ "$DEBUG2" == "true" ]
  then
    cp -av $1 $2 && result="${OK_MSG}" || result="${FAIL_MSG}"
  else
    cp -a $1 $2 && result="${OK_MSG}" || result="${FAIL_MSG}"
  fi
  print_result $msg_len "$result"
}

print_pending_op_msg()   # arg: msg
{
  echo -en "${1}"
}

print_result()  # args: msg_len result
{
  spaces_len=$(( $termwidth - $(( $1 + $RESULT_MSG_LEN )) ))
  spaces=""
  i=0
  while [ ! $i -gt $(($spaces_len - 1)) ]
  do
    spaces="$spaces "
    let "i++"
  done
  echo -e "${spaces}${2}"
  [ "$DEBUG2" == "true" ] && echo "#spaces was: ${#spaces}"
}

create_links()
{
  calculate_termwidth
  old_pwd="$PWD"
  # create symlinks in bin and sbin
  message "Creating busybox links in initramfs/bin/ ..."
  cd ${SOURCES_DIR}/bin/
  #  let's just link everything that's in busybox... (except commands we explicitly include
  #    findfs, blkid, e2fsck (fsck)... and of course, our own init
  for i in \
    [ [[ acpid addgroup adduser adjtimex arp arping ash awk base64 basename bb bbsh blockdev \
    brctl bunzip2 bzcat bzip2 cal cat catv chat chattr chgrp chmod chown chpasswd chpst chroot chrt \
    chvt cksum clear cmp comm conspy cp cpio crond cryptpw cttyhack cut date dd deallocvt delgroup \
    deluser depmod devmem df dhcprelay diff dirname dmesg dnsdomainname dos2unix du dumpkmap \
    dumpleases echo ed egrep eject env envdir envuidgid ether-wake expand expr false fatattr fbset \
    fdflush fdformat fdisk fgconsole fgrep find flock free freeramdisk fstrim fsync ftpd \
    fuser getopt getty ginit grep groups gunzip gzip halt hd hdparm head hexdump hostname httpd \
    hwclock id ifconfig ifdown ifenslave ifplugd ifup insmod install ionice iostat ip ipaddr \
    ipcrm ipcs iplink iproute iprule iptunnel kbd_mode kill killall killall5 last less linux32 \
    linux64 linuxrc ln loadfont loadkmap login losetup lpq lpr ls lsattr lsmod lsof lspci lsusb \
    lzcat lzma lzop lzopcat makedevs man md5sum mdev mesg microcom mkdir mkdosfs mke2fs mkfifo \
    mkfs.ext2 mkfs.vfat mknod mkpasswd mkswap mktemp modinfo modprobe more mount mountpoint mpstat mt \
    mv nameif nanddump nandwrite nbd-client nc netstat nice nmeter nohup nslookup ntpd openvt passwd \
    patch pgrep pidof ping pipe_progress pivot_root pkill pmap popmaildir poweroff powertop printenv \
    printf ps pscan pstree pwd pwdx raidautorun rdate readahead readlink realpath reboot renice reset \
    resize rev rm rmdir rmmod route rtcwake runlevel rx script scriptreplay sed sendmail seq setarch \
    setconsole setfont setkeycodes setlogcons setserial setsid setuidgid sh sha1sum sha256sum sha3sum \
    sha512sum showkey shuf sleep softlimit sort split start-stop-daemon stat strings stty su sum \
    swapoff swapon switch_root sync sysctl tac tail tar tee telnet telnetd test tftp tftpd time \
    timeout top touch tr traceroute true tty ttysize tunctl ubiattach ubidetach ubimkvol ubirmvol \
    ubirsvol ubiupdatevol udhcpc udhcpd umount uname unexpand uniq unix2dos unlink unlzma unlzop unxz \
    unzip uptime users usleep vconfig vi vlock volname wall watch watchdog wc wget which who whoami \
    whois xargs xz xzcat yes zcat zcip
  do
    msg="Linking:   ${LBon}$i${Boff} --> ${BGon}busybox${Boff} ..."
    msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
    print_pending_op_msg "$msg"
    ln -s busybox "$i" && result="$OK_MSG" || result="$FAIL_MSG"
    print_result $msg_len "$result"
  done

  # create links in /bin to executables in /sbin where we want to ensure busybox's own is not executed in
  # /bin instead of the executable in /sbin that we intend:
  # (   findfs, blkid, e2fsck (fsck fsck.ext2 fsck.ext3 fsck.ext4)...
  message "Creating NON-busybox links in initramfs/bin/ ..."
  for i in findfs blkid e2fsck fsck fsck.ext2 fsck.ext3 fsck.ext4
  do
    msg="Linking:   ${LBon}${i}${Boff} --> ${BGon}/sbin/${i}${Boff} ..."
    msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
    print_pending_op_msg "$msg"
    ln -s /sbin/$i "$i" && result="$OK_MSG" || result="$FAIL_MSG"
    print_result $msg_len "$result"
  done
  # of course our own init is in /, not busybox's in /bin or the traditional /sbin/init
  msg="Linking:   ${LBon}init${Boff} --> ${BGon}../init${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s ../init init && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  message "Creating lvm2 links in initramfs/sbin/ ..."
  cd ${SOURCES_DIR}/sbin/
  for i in lvchange lvconvert lvcreate lvdisplay lvextend lvmchange \
           lvmdiskscan lvmsadc lvmsar lvreduce lvremove lvrename lvresize \
           lvs lvscan pscan pvchange pvck pvcreate pvdisplay pvmove pvremove \
           pvs vgcfgbackup vgcfgrestore vgchange vgck vgconvert vgcreate \
           vgdisplay vgexport vgextend vgimport vgmerge vgmknodes vgreduce \
           vgremove vgrename vgs vgscan vgsplit
  do
    msg="Linking:   ${LBon}$i${Boff} --> ${BGon}lvm${Boff} ..."
    msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
    print_pending_op_msg "$msg"
    ln -s lvm "$i" && result="$OK_MSG" || result="$FAIL_MSG"
    print_result $msg_len "$result"
  done

  for i in fsck fsck.ext2 fsck.ext3 fsck.ext4
  do
    msg="Linking:   ${LBon}$i${Boff} --> ${BGon}e2fsck${Boff} ..."
    msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
    print_pending_op_msg "$msg"
    ln -s e2fsck "$i" && result="$OK_MSG" || result="$FAIL_MSG"
    print_result $msg_len "$result"
  done

  msg="Linking:   ${LBon}mdev${Boff} --> ${BGon}../bin/busybox${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s ../bin/busybox mdev && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  # of course our own init is in /, not busybox's in /bin or the traditional /sbin/init
  msg="Linking:   ${LBon}init${Boff} --> ${BGon}../init${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s ../init init && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  msg="Linking:   ${LBon}modprobe${Boff} --> ${BGon}../bin/kmod${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s ../bin/kmod modprobe && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  msg="Linking:   ${LBon}udevadm${Boff} --> ${BGon}../bin/udevadm${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s ../bin/udevadm udevadm && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

#splash_helper -> //sbin/fbcondecor_helper
  if [ "${init_splash}" == "yes" ]
  then
    msg="Linking:   ${LBon}splash_helper${Boff} --> ${BGon}//sbin/fbcondecor_helper${Boff} ..."
    msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
    print_pending_op_msg "$msg"
    ln -s //sbin/fbcondecor_helper splash_helper && result="$OK_MSG" || result="$FAIL_MSG"
  else
    msg="Skipping linking for splash... (not requested)"
    msg_len=${#msg}   # adjustment for non-printingchars not needed
  fi
  print_result $msg_len "$result"

  message "Creating links in initramfs/dev/vc/ ..."
  cd ${SOURCES_DIR}/dev/vc/
  msg="Linking:   ${LBon}0${Boff} --> ${BGon}../console${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s ../console 0 && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  message "Creating links in initramfs/usr/ ..."
  cd ${SOURCES_DIR}/usr/
  msg="Linking:   ${LBon}lib${Boff} --> ${BGon}../lib${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s ../lib lib && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  msg="Linking:   ${LBon}lib64${Boff} --> ${BGon}../lib${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s ../lib lib64 && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  message "Creating links in initramfs/ ..."
  cd ${SOURCES_DIR}/
  msg="Linking:   ${LBon}lib64${Boff} --> ${BGon}lib${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s lib lib64 && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  msg="Linking:   ${LBon}linuxrc${Boff} --> ${BGon}init${Boff} ..."
  msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  ln -s init linuxrc && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

  cd $old_pwd
}

build_dir_tree()
{
message "Building directory tree in ${SOURCES_DIR} ..."
local treelist
if [ "${init_splash}" == "yes" ]
then
    treelist=$(grep -v "#" ${MAKE_DIR}/initramfs_dir_tree)
else
    treelist=$(grep -v "#" ${MAKE_DIR}/initramfs_dir_tree | grep -v splash)
fi
for i in ${treelist}
do
  msg="${BGon}*${Boff} $i ..."
  msg_len=$(( ${#msg} - $(( ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  if [ ! -e ${SOURCES_DIR}$i ]
  then
    mkdir ${SOURCES_DIR}$i && result="$OK_MSG" || result="$FAIL_MSG"
  else
    already_msg=" directory $i already created in ${SOURCES_DIR} "
    let "msg_len=$msg_len + ${#already_msg}"
    echo -en "$already_msg"
    result="$NA_MSG"
  fi
  print_result $msg_len "$result"
done
}

create_device_nodes()
{
  calculate_termwidth

  # character special device nodes in dev
  make_one_device_node ${SOURCES_DIR}/dev/console c 5 1
  make_one_device_node ${SOURCES_DIR}/dev/null c 1 3
  make_one_device_node ${SOURCES_DIR}/dev/tty1 c 4 1
  make_one_device_node ${SOURCES_DIR}/dev/urandom c 1 9
  make_one_device_node ${SOURCES_DIR}/dev/mapper/control c 10 236

  # block device nodes in dev
  make_one_device_node ${SOURCES_DIR}/dev/sda b 8 0
  make_one_device_node ${SOURCES_DIR}/dev/sda1 b 8 1
  make_one_device_node ${SOURCES_DIR}/dev/sda2 b 8 2
  make_one_device_node ${SOURCES_DIR}/dev/sda3 b 8 3

  make_one_device_node ${SOURCES_DIR}/dev/sdb b 8 16
  make_one_device_node ${SOURCES_DIR}/dev/sdb1 b 8 17
  make_one_device_node ${SOURCES_DIR}/dev/sdb2 b 8 18
  make_one_device_node ${SOURCES_DIR}/dev/sdb3 b 8 19

  make_one_device_node ${SOURCES_DIR}/dev/sdc b 8 32
  make_one_device_node ${SOURCES_DIR}/dev/sdc1 b 8 33
  make_one_device_node ${SOURCES_DIR}/dev/sdc2 b 8 34
  make_one_device_node ${SOURCES_DIR}/dev/sdc3 b 8 35

  make_one_device_node ${SOURCES_DIR}/dev/sdd b 8 48
  make_one_device_node ${SOURCES_DIR}/dev/sdd1 b 8 49
  make_one_device_node ${SOURCES_DIR}/dev/sdd2 b 8 50
  make_one_device_node ${SOURCES_DIR}/dev/sdd3 b 8 51

  make_one_device_node ${SOURCES_DIR}/dev/sde b 8 64
  make_one_device_node ${SOURCES_DIR}/dev/sde1 b 8 65
  make_one_device_node ${SOURCES_DIR}/dev/sde2 b 8 66
  make_one_device_node ${SOURCES_DIR}/dev/sde3 b 8 67

  make_one_device_node ${SOURCES_DIR}/dev/sdf b 8 80
  make_one_device_node ${SOURCES_DIR}/dev/sdf1 b 8 81
  make_one_device_node ${SOURCES_DIR}/dev/sdf2 b 8 82
  make_one_device_node ${SOURCES_DIR}/dev/sdf3 b 8 83

  make_one_device_node ${SOURCES_DIR}/dev/sdg b 8 96
  make_one_device_node ${SOURCES_DIR}/dev/sdg1 b 8 97
  make_one_device_node ${SOURCES_DIR}/dev/sdg2 b 8 98
  make_one_device_node ${SOURCES_DIR}/dev/sdg3 b 8 99

  make_one_device_node ${SOURCES_DIR}/dev/sdh b 8 112
  make_one_device_node ${SOURCES_DIR}/dev/sdh1 b 8 113
  make_one_device_node ${SOURCES_DIR}/dev/sdh2 b 8 114
  make_one_device_node ${SOURCES_DIR}/dev/sdh3 b 8 115

  make_one_device_node ${SOURCES_DIR}/dev/sdi b 8 128
  make_one_device_node ${SOURCES_DIR}/dev/sdi1 b 8 129
  make_one_device_node ${SOURCES_DIR}/dev/sdi2 b 8 130
  make_one_device_node ${SOURCES_DIR}/dev/sdi3 b 8 131

  make_one_device_node ${SOURCES_DIR}/dev/sdj b 8 144
  make_one_device_node ${SOURCES_DIR}/dev/sdj1 b 8 145
  make_one_device_node ${SOURCES_DIR}/dev/sdj2 b 8 146
  make_one_device_node ${SOURCES_DIR}/dev/sdj3 b 8 147

}

make_one_device_node()  # args: name type[c|b] MAJOR MINOR
{
  # mknod [option] name type [major minor]
  #  options: {-m|--mode=MODE] [-z|--context=CTX]
  #  types: p=FIFO, b=block, c=character

  node_name="$1"
  node_type="$2"
  node_MAJOR="$3"
  node_MINOR="$4"
  msg="${BGon}*${Boff} ${node_name} ${node_type} ${node_MAJOR} ${node_MINOR} ..."
  msg_len=$(( ${#msg} - $(( ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
  print_pending_op_msg "$msg"
  mknod "${node_name}" "${node_type}" ${node_MAJOR} ${node_MINOR} \
     && result="$OK_MSG" || result="$FAIL_MSG"
  print_result $msg_len "$result"

}

copy_dependent_libraries()
{
  calculate_termwidth
  # so far, I've identified three cases in the output of ldd /sbin/cryptsetup and ldd /sbin/lvm (and /sbin/e2fsck):
  # (1) doesn't exist            : linux-vdso.so.1 (0x00007ffff5ffe000)
  # (2) symlink and target shown : libcryptsetup.so.4 => /usr/lib64/libcryptsetup.so.4 (0x00007f168d7e4000)
  # (3) symlink shown            : /lib64/ld-linux-x86-64.so.2 (0x00007f168da0e000) or /lib/ld-linux.so.2
  # (4) strange look for use-ld  : use-ld=gold => not found
  # parsing strategy: grep -v "use-ld" to elim (4); grep -v "linux-vdso" to elim (1); 
  #   id (2) by "=>"; id (3) by leading "/"
  # also, there is a lot of duplication between cryptsetup and lvm dependencies, so check [ -e ] first

  # Process the dynamic executables in /bin to identify libraries they depend on
  echo "# temporary file to capture list of libraries upon which my initramfs executables depend"
  # /bin
  for i in $bin_dyn_executables
  do
    ldd /bin/${i} | grep -v "use-ld" | grep -v "linux-vdso.so.1" | cut -d'(' -f1 >> $tmpfile
  done
  # /usr/bin
  for i in $usr_bin_dyn_executables
  do
    ldd /usr/bin/${i} | grep -v "use-ld" | grep -v "linux-vdso.so.1" | cut -d'(' -f1 >> $tmpfile
  done
  # /sbin
  for i in $sbin_dyn_executables
  do
    ldd /sbin/${i} | grep -v "use-ld" | grep -v "linux-vdso.so.1" | cut -d'(' -f1 >> $tmpfile
  done

  # eliminate duplicate entries and sort to a new file
  grep -v "#" $tmpfile | sort -u > $tmpfile2
  while read line
  do
    [ "$DEBUG_LIB_COPY" == "true" ] && message "---[ New line to examine: ( $line ) ]---"
    link_index=`expr index "$line" "=>"`
    [ "$DEBUG_LIB_COPY" == "true" ] && echo "link_index: $link_index"
    if [ $link_index -gt 0 ]   # if true (2), else (1) or (3)
    then # both shown, but real symlink is on right
      linkname=$(echo $line | cut -c $(( $link_index + 3 ))- )
      [ "$DEBUG_LIB_COPY" == "true" ] && echo "Case 2 (symlink and target shown) linkname: $linkname"
      real_linkname_index=`expr index "$( ls -al $linkname )" "/"`
      [ "$DEBUG_LIB_COPY" == "true" ] && echo "real_linkname_index: $real_linkname_index"
      real_link_line=$( echo "$( ls -al $linkname )" | cut -c $(( $real_linkname_index - 1 ))- | sed 's/\ //' )
      [ "$DEBUG_LIB_COPY" == "true" ] && echo "real_link_line: $real_link_line"
      real_link_index=`expr index "$real_link_line" ">"`
      [ "$DEBUG_LIB_COPY" == "true" ] && echo "real_link_index: $real_link_index"

      #if real_link_index=0 it's not actually a "link" but rather a hard filename
      #  in this case, only copy, don't link
      if [ $real_link_index -eq 0 ]
      then
        real_target="$real_link_line"
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "real_target: $real_target"
        real_link_directory=${SOURCES_DIR}${real_target%/*}/
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "real_link_directory: $real_link_directory"
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "about to execute: [ ! -e $real_link_directory$real_target ] && copy_one_part $make_directory$real_target $real_link_directory"
        copy_one_part "$real_target" "$real_link_directory"
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "--------------------------------------------"
      else
        real_target=$( echo "$real_link_line" | cut -c $(( $real_link_index + 2 ))- )
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "real_target: $real_target"
        real_link_name=$( echo "$real_link_line" | cut -c -$(( $real_link_index - 2 )) )
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "real_link_name: $real_link_name"
        make_directory=${real_link_name%/*}/
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "make_directory: $make_directory"
        real_link_directory=${SOURCES_DIR}${real_link_name%/*}/
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "real_link_directory: $real_link_directory"
        really_real_link_name=$( echo ${real_link_name} | sed -e "s%${real_link_name%/*}/%%" )
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "really_real_link_name: $really_real_link_name"
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "about to execute: [ ! -e $real_link_directory$real_target ] && copy_one_part $make_directory$real_target $real_link_directory"
        if [ ! -e $real_link_directory$real_target ] 
        then
          copy_one_part "$make_directory$real_target" "$real_link_directory"
        else
          msg=" {file $make_directory$real_target already copied to  $real_link_directory} "
          msg_len=${#msg}
          print_pending_op_msg "$msg"
          result="$NA_MSG"
          print_result $msg_len "$result"
        fi

        old_pwd=$PWD
        cd $real_link_directory
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "just changed from directory [ $old_pwd ] to directory: [ $PWD ]"
        msg="Linking:   ${LBon}${really_real_link_name}${Boff} --> ${BGon}${real_target}${Boff} ..."
        msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
        [ "$DEBUG_LIB_COPY" == "true" ] && echo "about to execute: ln -s $real_target $really_real_link_name"
        print_pending_op_msg "$msg"
        if [ ! -e $really_real_link_name ]
        then
          ln -s $real_target $really_real_link_name && result="$OK_MSG" || result="$FAIL_MSG"
        else
          already_msg=" {link already created} "
          let "msg_len=$msg_len + ${#already_msg}"
          echo -en "$already_msg"
          result="$NA_MSG"
        fi
        print_result $msg_len "$result"
        cd $old_pwd
      fi
    else  # (3) symlink shown: /lib64/ld-linux-x86-64.so.2 (0x00007f168da0e000) or /lib/ld-linux.so.2
      # parsing strategy: id (3) by leading "/"; ignore (1)
      # also, there is a lot of duplication between cryptsetup and lvm dependencies, so check [ -e ] first
#      linkname_index=`expr index "$(ls -al /lib64/ld-linux-x86-64.so.2)" "/"`
      linkname_index=`expr index "$(ls -al $(echo $line | cut -d" " -f1))" "/"`
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "Case 3 (symlink shown) linkname_index: $linkname_index"
#      linkname=$( ls -al /lib64/ld-linux-x86-64.so.2 | cut -c $linkname_index- )
      linkname=$( ls -al $(echo $line | cut -d" " -f1) | cut -c $linkname_index- )
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "linkname: $linkname"
      real_name_index=`expr index "$linkname" ">"`
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "real_name_index: $real_name_index"
      real_target=$( echo "$linkname" | cut -c $(( $real_name_index + 2 ))- )
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "real_target: $real_target"
      real_link_name=$( echo "$linkname" | cut -c -$(( $real_name_index - 2 )) )
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "real_link_name: $real_link_name"
      make_directory=${real_link_name%/*}/
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "make_directory: $make_directory"
      real_link_directory=${SOURCES_DIR}${real_link_name%/*}/
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "real_link_directory: $real_link_directory"
      really_real_link_name=$( echo ${real_link_name} | sed -e "s%${real_link_name%/*}/%%" )
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "really_real_link_name: $really_real_link_name"

      if [ ! -e $real_link_directory$real_target ]
      then
        copy_one_part "$make_directory$real_target" "$real_link_directory"
      else
        msg=" {file $make_directory$real_target already copied to  $real_link_directory} "
        msg_len=${#msg}
        print_pending_op_msg "$msg"
        result="$NA_MSG"
        print_result $msg_len "$result"
      fi

      old_pwd=$PWD
      cd $real_link_directory
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "just changed from directory [ $old_pwd ] to directory: [ $PWD ]"
      msg="Linking:   ${LBon}${really_real_link_name}${Boff} --> ${BGon}${real_target}${Boff} ..."
      msg_len=$(( ${#msg} - $(( ${#LBon} + ${#Boff} + ${#BGon} + ${#Boff} )) ))   # adjusted for non-printingchars
      [ "$DEBUG_LIB_COPY2" == "true" ] && echo "about to execute: ln -s $real_target $really_real_link_name"
      print_pending_op_msg "$msg"
      if [ ! -e $really_real_link_name ]
      then
        ln -s $real_target $really_real_link_name && result="$OK_MSG" || result="$FAIL_MSG"
      else
        already_msg=" {link already created} "
        let "msg_len=$msg_len + ${#already_msg}"
        echo -en "$already_msg"
        result="$NA_MSG"
      fi
      print_result $msg_len "$result"
      cd $old_pwd
    fi
  done < $tmpfile2
}

#---[ Main Script ]-------------------------------------------------------
# Create the required directory structure -- maintain the file
#   ${MAKE_DIR}/initramfs_dir_tree to tailor this
separator "make_sources.sh - $BUILD"
checkroot
display_config
# determine if splash is requested in init.conf
eval $(grep "splash" init.conf | grep -v "#")
[ "${init_splash}" == "yes" ] && message "splash requested" || message "splash not requested"
calculate_termwidth

separator "Build Directory Tree"
build_dir_tree

separator "Create Device Nodes"
create_device_nodes

separator "Check for Parts"
check_for_parts

separator "Copy Parts"
copy_parts

separator "Create Symlinks"
create_links

separator "Copy Dependent Libraries"
copy_dependent_libraries

separator "Create the BUILD reference file"
echo "BUILD=\"${BUILD}\"" > ${SOURCES_DIR}/BUILD

message "cleaning up..."
# don't remove these temporary files if debugging...
[ ! "$DEBUG" == "true" ] && rm $tmpfile
[ ! "$DEBUG" == "true" ] && rm $tmpfile2
message "All Done"
