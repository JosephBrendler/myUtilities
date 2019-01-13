#!/bin/bash
# make_sources.sh (formerly mkinitramfs.sh) -- set up my custom initramfs
# Joe Brendler - 9 September 2014
#    for version history and "credits", see the accompanying "historical_notes" file

# --- Define local variables -----------------------------------

# the GLOBALS file identifies the BUILD, SOURCES_DIR (e.g. /usr/src/initramfs),
#   and the MAKE_DIR (parent dir of this script)
source GLOBALS
source ${SCRIPT_HEADER_DIR}/script_header_brendlefly
# script header will over-ride BUILD, but globals must be sourced 1st to get _DIRs
BUILD="${KERNEL_VERSION}-${DATE_STAMP}"

VERBOSE=$TRUE
#VERBOSE=$FALSE
verbosity=2


# define lists of files that need to be copied
config_files="init.conf README LICENSE"
other_content_src=("/usr/local/sbin/script_header_brendlefly" "${MAKE_DIR}/etc/lvm/lvm.conf"        "${MAKE_DIR}/etc/modules")
other_content_dest=("${SOURCES_DIR}/"                         "${SOURCES_DIR}/etc/lvm/"  "${SOURCES_DIR}/etc/")

source ${MAKE_DIR}/dyn_executables_header

# define lists of links that need to be created in /bin
#   create links in /bin to executables in /sbin to ensure we do not use busybox "version" --
#   findfs, blkid, e2fsck (fsck fsck.ext2 fsck.ext3 fsck.ext4)...
non_busybox_bin_links="findfs blkid e2fsck fsck fsck.ext2 fsck.ext3 fsck.ext4"

#   references to busybox.  just link everything in busybox, except commands we do NOT want busybox to run --
#   findfs, blkid, e2fsck, findfs, fsck, (fsck.ext2, fsck.ext3, fsck.ext4), and of course our own init
busybox_link_list="\
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
    whois xargs xz xzcat yes zcat zcip"

# define lists of links that need to be created in /sbin
#   references to lvm
lvm_link_list="\
    lvchange lvconvert lvcreate lvdisplay lvextend lvmchange \
    lvmdiskscan lvmsadc lvmsar lvreduce lvremove lvrename lvresize \
    lvs lvscan pscan pvchange pvck pvcreate pvdisplay pvmove pvremove \
    pvs vgcfgbackup vgcfgrestore vgchange vgck vgconvert vgcreate \
    vgdisplay vgexport vgextend vgimport vgmerge vgmknodes vgreduce \
    vgremove vgrename vgs vgscan vgsplit"

#   references to e2fsck
e2fsck_link_list="fsck fsck.ext2 fsck.ext3 fsck.ext4"

# use this set of arrays to define other links that need to be created in the associated dirs
#   initialize the arrays with values associated with /
other_link_dir=(    "/"     "/"      )
other_link_target=( "lib"   "init"   )
other_link_name=(   "lib64" "linuxrc")

#   add to the arrays values associated with /bin/
other_link_dir+=(    "/bin/"   )
other_link_target+=( "../init" )
other_link_name+=(   "init"    )

#   add to the arrays values associated with /sbin/
other_link_dir+=(    "/sbin/"         "/sbin/"  "/sbin/"      "/sbin/"         )
other_link_target+=( "../bin/busybox" "../init" "../bin/kmod" "../bin/udevadm" )
other_link_name+=(   "mdev"           "init"    "modprobe"    "udevadm"        )

#   add to the arrays values associated with /usr/
other_link_dir+=(    "/usr/"  "/usr/")
other_link_target+=( "../lib" "../lib")
other_link_name+=(   "lib"    "lib64")

#   add to the arrays values associated with /dev/
other_link_dir+=(    "/dev/vc/"   )
other_link_target+=( "../console" )
other_link_name+=(   "0"          )

#---[ functions ]-----------------------------------------------

display_config()
{
  d_message "SOURCES_DIR: "${SOURCES_DIR} 3
  d_message "MAKE_DIR: "${MAKE_DIR} 3
}

check_for_parts()
{
  PARTSTRING=""
  #look for lvm and cryptsetup, and if not found, ask if user wants to install them
  d_message_n "Finding lvm..." 1
  if [ ! -e /sbin/lvm ]
  then d_right_status 1 1; PARTSTRING+=" sys-fs/lvm2";
  else d_right_status 0 1; fi

  d_message_n "Finding cryptsetup..." 1
  if [ ! -e /sbin/cryptsetup ]
  then d_right_status 1 1; PARTSTRING+=" sys-fs/cryptsetup";
  else d_right_status 0 1; fi

  # if splash is requested, check for it
  if [ "${init_splash}" == "yes" ]
  then
    d_message_n "Finding splashutils..." 1
    if [ ! -e /sbin/fbcondecor_helper ]
    then d_right_status 1 1; PARTSTRING+=" media-gfx/splashutils";
    else d_right_status 0 1; fi
  else
    d_message "Skipping check for splashutils... (not requested)" 1
  fi

  # if missing parts are identified, confirm user wants to emerge them, the do so
  if [ ! -z "${PARTSTRING}" ]
  then
    answer="z"
    E_message "Necessary components appear to be missing [${BRon}${PARTSTRING} ${BYon}]."
    prompt "${BRon}*${BYon} Do you want to install them?${Boff}"
    if [[ "$answer" == "y" ]]
    then
      emerge -av ${PARTSTRING}
    else
      exit 1
    fi
  fi
}

copy_parts()
{
  d_message "Copying necessary executable files..." 1
# Maybe future TODO - use progress meter if not $VERBOSE
#  steps=${bin_dyn_executables} ${bin_non_dyn_executables} \
#        ${sbin_dyn_executables} ${sbin_non_dyn_executables} \
#        ${usr_bin_dyn_executables} ${usr_bin_non_dyn_executables}
#  set $steps   # this will let us handle and count them as positional parameters
#  num_steps=$#; step_num=0

  #copy /bin executable parts
  for i in ${bin_dyn_executables} ${bin_non_dyn_executables}
  do copy_one_part /bin/$i ${SOURCES_DIR}/bin/; done
  # /sbin
  for i in ${sbin_dyn_executables} ${sbin_non_dyn_executables}
  do copy_one_part /sbin/$i ${SOURCES_DIR}/sbin/; done
  # /usr/bin
  for i in ${usr_bin_dyn_executables} ${usr_bin_non_dyn_executables}
  do copy_one_part /usr/bin/$i ${SOURCES_DIR}/usr/bin/; done

  if [ "${init_splash}" == "yes" ]
  then copy_one_part /sbin/fbcondecor_helper ${SOURCES_DIR}/sbin/
  else d_message "Skipping copy for /sbin/fbcondecor_helper... (splash not requested)" 2
  fi
  copy_one_part ./init ${SOURCES_DIR}/

  # copy config files
  d_message "Copying necessary configuration files..." 1
  for i in $config_files
  do copy_one_part ${MAKE_DIR}/$i ${SOURCES_DIR}/; done

  # copy other required content
  d_message "Copying other required content ..." 1
  for ((i=0; i<${#other_content_src[@]}; i++))
  do copy_one_part ${other_content_src[i]} ${other_content_dest[i]}; done
  if [ "${init_splash}" == "yes" ]
  then
    copy_one_part ${MAKE_DIR}/etc/initrd.splash ${SOURCES_DIR}/etc/
    copy_one_part ${MAKE_DIR}/etc/splash ${SOURCES_DIR}/etc/
  else
    d_message "Skipping copy for splash files in /etc/ ... (splash not requested)" 2
  fi

}

copy_one_part()
{
  d_message_n "Copying [ $1 ] to [ $2 ]..." 2
  if [[ $verbosity -ge 3 ]]
  then cp -av $1 $2 ; d_right_status $? 2
  else cp -a $1 $2 ; d_right_status $? 2
  fi
}

create_links()
{
  old_pwd="$PWD"
  # create symlinks in /bin
  d_message "Creating busybox links in initramfs/bin/ ..." 1
  cd ${SOURCES_DIR}/bin/
  for i in $busybox_link_list
  do d_message_n "Linking:   ${LBon}$i${Boff} --> ${BGon}busybox${Boff} ..." 2;
  ln -s busybox "$i" ; d_right_status $? 2; done

  d_message "Creating NON-busybox links in initramfs/bin/ ..." 1
  for i in $non_busybox_bin_links
  do d_message_n "Linking:   ${LBon}${i}${Boff} --> ${BGon}/sbin/${i}${Boff} ..." 2;
  ln -s /sbin/$i "$i" ; d_right_status $? 2; done

  # create symlinks in /sbin
  d_message "Creating lvm2 links in initramfs/sbin/ ..." 1
  cd ${SOURCES_DIR}/sbin/
  for i in $lvm_link_list
  do d_message_n "Linking:   ${LBon}$i${Boff} --> ${BGon}lvm${Boff} ..." 2;
  ln -s lvm "$i" ; d_right_status $? 2; done
  for i in $e2fsck_link_list
  do d_message_n "Linking:   ${LBon}$i${Boff} --> ${BGon}e2fsck${Boff} ..." 2;
  ln -s e2fsck "$i" ; d_right_status $? 2; done
  #splash_helper -> //sbin/fbcondecor_helper
  if [ "${init_splash}" == "yes" ]
  then d_message_n "Linking:   ${LBon}splash_helper${Boff} --> ${BGon}//sbin/fbcondecor_helper${Boff} ..." 2;
    ln -s //sbin/fbcondecor_helper splash_helper ; d_right_status $? 2
  else d_message "Skipping linking for splash... (not requested)" 2;
  fi

  # create links to other executables in associated dirs, using array set
  d_message "Creating [${#other_link_name[@]}] additional links..." 1
  for ((i=0; i<${#other_link_name[@]}; i++))
  do d_message_n "Linking:   ${BBon}[${other_link_dir[i]}] ${LBon}${other_link_name[i]}${Boff} --> ${BGon}${other_link_target[i]}${Boff} ..." 2;
  cd ${SOURCES_DIR}${other_link_dir[i]}; ln -s "${other_link_target[i]}"  "${other_link_name[i]}" ; d_right_status $? 2; done

  cd $old_pwd
}

build_dir_tree()
{
d_message "Building directory tree in ${SOURCES_DIR} ..." 1
local treelist
if [ "${init_splash}" == "yes" ]
then
    treelist=$(grep -v "#" ${MAKE_DIR}/initramfs_dir_tree)
else
    treelist=$(grep -v "#" ${MAKE_DIR}/initramfs_dir_tree | grep -v splash)
fi
for i in ${treelist}
do
  if [ ! -e ${SOURCES_DIR}$i ]
  then
    d_message_n " Creating ${SOURCES_DIR}/$i..." 2; mkdir ${SOURCES_DIR}$i ; d_right_status $? 2
  else
    d_message_n " Found existing ${SOURCES_DIR}/$i..." 2; d_right_status $? 2
  fi
done
}

create_device_nodes()
{
## TODO - test if this is really necessary, now that we have mdev
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
  #  options: {-m|--mode=MODE] [-z|--context=CTX], types: p=FIFO, b=block, c=character
  node_name="$1"; node_type="$2"; node_MAJOR="$3"; node_MINOR="$4"
  d_message_n "${BGon}*${Boff} ${node_name} ${node_type} ${node_MAJOR} ${node_MINOR} ..." 2
  mknod "${node_name}" "${node_type}" ${node_MAJOR} ${node_MINOR} ; d_right_status $? 2
}

copy_dependent_libraries()
{
  # Beginning with version 5.3.1, I'm using lddtree (from app-misc/pax-utils) instead of ldd.
  # This appears to simplify the situation to three cases (one of which is trivial):
  # (1) symlink_name => dir_name/target_name shown
  # (2) target_name => dir_name/target_name        (where target_name is the executable)
  # (3) dyn_executable (interpreter => /lib{64}/ld-linux{-x86-64}.so.2) {ignore with grep -v}
  # parsing strategy:
  # Ignore case (3) - (trivial) the dyn_executable is already copied, and ld-linux is on the list separately
  # For case (2) - just make sure the target executable (dependency) gets copied if it hasn't been already
  # For each case (1), copy the target executable to - and create the symlink in - the ${SOURCES_DIR}

  # General algorithm:  process the dynamic executables to identify libraries they depend on --
  #   for each dyn_executable, use which to locate it, and lddtree to list all dependencies.
  #   ignore case (3) lines with grep -v interpreter; trim leading and trailing whitespace;
  #   sort and eliminate duplicates; we need only the third field of lddtree output (/target/path/target_name)
  d_message "Copying dependent libraries ..." 1
  for x in $( for i in $bin_dyn_executables $usr_bin_dyn_executables $sbin_dyn_executables; do lddtree $(which $i); done | \
    grep -v interpreter | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' | sort -u | cut -d' ' -f3)
  do
    # run the "file" command on each /target/path/target_name listed, the second field of
    #   this output shows if it is case (1) symlink or (2) ELF
    line=$(file $x)
    d_message "---[ New line to examine: ( ${line} ) ]---" 3
    set ${line}
    case $2 in
      "ELF" )
        # just copy the target executable (first item in the line)
        target_name=$(basename $1 | sed 's/:$//')   # drop the trailing colon
        dir_name=$(dirname $1)
        d_message "  Case 2 (ELF). dir_name=[$dir_name], target_name=[$target_name]" 3
        d_message "  Copy/Link ${SOURCES_DIR}${dir_name}/$target_name..." 2
        d_message "  about to execute: [[ ! -e ${SOURCES_DIR}${dir_name}/$target_name ]] && copy_one_part \"${dir_name}/${target_name}\" \"${SOURCES_DIR}${dir_name}/\"" 3
        [[ ! -e ${SOURCES_DIR}${dir_name}/${target_name} ]] && \
          copy_one_part "${dir_name}/${target_name}" "${SOURCES_DIR}${dir_name}/"
        ;;
      "symbolic" )
        # copy the target executable (last item in the line) and create the symlink (first item in the line) to it
        target_name=${!#}    # last positional parameter
        link_name=$( basename $1 | sed 's/:$//' )  # drop the trailing colon
        dir_name=$( dirname $1 )
        # first copy the target
        d_message "  Case 1 (symlink) dir_name=[$dir_name], link_name=[$link_name], target_name=[$target_name]" 3
        d_message "  Copy/Link ${SOURCES_DIR}${dir_name}/$target_name..." 2
        d_message "  about to execute: [[ ! -e ${SOURCES_DIR}${dir_name}/$target_name ]] && copy_one_part \"${dir_name}/${target_name}\" \"${SOURCES_DIR}${dir_name}/\"" 3
        [[ ! -e ${SOURCES_DIR}${dir_name}/${target_name} ]] && \
          copy_one_part "${dir_name}/${target_name}" "${SOURCES_DIR}${dir_name}/"
        # next, create the link
        old_pwd=$PWD
        cd ${SOURCES_DIR}${dir_name}
        d_message "just changed from directory [ $old_pwd ] to directory: [ $PWD ]" 3
        d_message_n "Linking:   ${LBon}${link_name}${Boff} --> ${BGon}${dir_name}/${target_name}${Boff} ..." 2
        if [ ! -e ${SOURCES_DIR}${dir_name}/${link_name} ]
        then
          ln -s $target_name $link_name ; d_right_status $? 2
        else
          d_message_n " {link already created} " 2; d_right_status $? 2
        fi
        cd $old_pwd
        ;;
      * )
       E_message "error in copying/linking dependencies"
       exit 1
       ;;
    esac
    d_message "--------------------------------------------" 3
  done
}

#---[ Main Script ]-------------------------------------------------------
# Create the required directory structure -- maintain the file
#   ${MAKE_DIR}/initramfs_dir_tree to tailor this
separator "Make Sources"  "mkinitramfs-$BUILD"
checkroot
display_config
# determine if splash is requested in init.conf
eval $(grep "splash" init.conf | grep -v "#")
[ "${init_splash}" == "yes" ] && d_message "splash requested" 1 || d_message "splash not requested" 1


separator "Build Directory Tree"  "mkinitramfs-$BUILD"
build_dir_tree

separator "Create Device Nodes"  "mkinitramfs-$BUILD"
#create_device_nodes  (is this necessary?)

separator "Check for Parts"  "mkinitramfs-$BUILD"
check_for_parts

separator "Copy Parts"  "mkinitramfs-$BUILD"
copy_parts

separator "Create Symlinks"  "mkinitramfs-$BUILD"
create_links

separator "Copy Dependent Libraries"  "mkinitramfs-$BUILD"
copy_dependent_libraries

separator "Create the BUILD reference file"  "mkinitramfs-$BUILD"
echo "BUILD=\"${BUILD}\"" > ${SOURCES_DIR}/BUILD

d_message "cleaning up..." 1
# nothing to do here anymore...
d_message "All Done" 1
