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

# identify config file
[[ -e ${MAKE_DIR}/init.conf ]] && CONF_DIR=${MAKE_DIR}
[[ -e /etc/mkinitramfs/init.conf ]] && CONF_DIR="/etc/mkinitramfs"

# define lists of files that need to be copied
config_file="${CONF_DIR}/init.conf"
admin_files="README LICENSE"
other_content_src=("/usr/local/sbin/script_header_brendlefly" "${MAKE_DIR}/etc/lvm/lvm.conf"        "${MAKE_DIR}/etc/modules")
other_content_dest=("${SOURCES_DIR}/"                         "${SOURCES_DIR}/etc/lvm/"  "${SOURCES_DIR}/etc/")

source ${MAKE_DIR}/dyn_executables_header

#   link everything in busybox, except commands we do NOT want busybox to run --
#   modprobe-->kmod, blkid, e2fsck, find, findfs, fsck, (fsck.ext2, fsck.ext3, fsck.ext4), and of course our own init
busybox_link_list="\
    [ [[ acpid addgroup adduser adjtimex arp arping ash awk base64 basename bb bbsh blockdev \
    brctl bunzip2 bzcat bzip2 cal cat catv chat chattr chgrp chmod chown chpasswd chpst chroot chrt \
    chvt cksum clear cmp comm conspy cp cpio crond cryptpw cttyhack cut date dd deallocvt delgroup \
    deluser depmod devmem df dhcprelay diff dirname dmesg dnsdomainname dos2unix du dumpkmap \
    dumpleases echo ed egrep eject env envdir envuidgid ether-wake expand expr false fatattr fbset \
    fdflush fdformat fdisk fgconsole fgrep flock free freeramdisk fstrim fsync ftpd \
    fuser getopt getty ginit grep groups gunzip gzip halt hd hdparm head hexdump hostname httpd \
    hwclock id ifconfig ifdown ifenslave ifplugd ifup insmod install ionice iostat ip ipaddr \
    ipcrm ipcs iplink iproute iprule iptunnel kbd_mode kill killall killall5 last less linux32 \
    linux64 linuxrc ln loadfont loadkmap login losetup lpq lpr ls lsattr lsmod lsof lspci lsusb \
    lzcat lzma lzop lzopcat makedevs man md5sum mdev mesg microcom mkdir mkdosfs mke2fs mkfifo \
    mkfs.ext2 mkfs.vfat mknod mkpasswd mkswap mktemp modinfo more mount mountpoint mpstat mt \
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
    lvchange lvconvert lvcreate lvdisplay lvextend lvmchange lvmconfig \
    lvmdiskscan lvmsadc lvmsar lvreduce lvremove lvrename lvresize \
    lvs lvscan pvchange pvck pvcreate pvdisplay pvmove pvremove \
    pvs vgcfgbackup vgcfgrestore vgchange vgck vgconvert vgcreate \
    vgdisplay vgexport vgextend vgimport vgimportclone vgmerge vgmknodes \
    vgreduce vgremove vgrename vgs vgscan vgsplit"

#   references to e2fsck
e2fsck_link_list="fsck fsck.ext2 fsck.ext3 fsck.ext4"

# use this set of arrays to define other links that need to be created
# in the associated dirs (each "column" is dir, target, link-name)

#   initialize the arrays with values associated with /
other_link_dir=(    "/"     "/"      )
other_link_target=( "lib"   "init"   )
other_link_name=(   "lib64" "linuxrc")

# note 27 Dec 24 - w merged-usr all esecutables are now in /usr/bin
#   add to the arrays values associated with /bin/ (link relative to target /usr/bin in ../../init)
other_link_dir+=(    "/bin/"   )
other_link_target+=( "../../init" )
other_link_name+=(   "init"    )

#   add to the arrays values associated with /sbin/ - used to link more from /bin /sbin /usr/ssbin, but w merged-usr; dont need 
other_link_dir+=(    "/sbin/"   )
other_link_target+=( "kmod"     )
other_link_name+=(   "modprobe" )

#   add to the arrays values associated with /usr/
other_link_dir+=(    "/usr/"  "/usr/")
other_link_target+=( "../lib" "../lib")
other_link_name+=(   "lib"    "lib64")

#   add to the arrays values associated with /usr/bin/
# find is excluded from busybox and provided by gfind (dyn-executable)
other_link_dir+=(    "/usr/bin/" )
other_link_target+=( "gfind" )
other_link_name+=(   "find" )

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

  d_message_n "Finding cpio..." 1
  if [ ! -e /bin/cpio ]
  then d_right_status 1 1; PARTSTRING+=" app-arch/cpio";
  else d_right_status 0 1; fi

  d_message_n "Finding grub..." 1
  if [ ! -e /usr/sbin/grub-install ]
  then d_right_status 1 1; PARTSTRING+=" sys-boot/grub";
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
  # update 27 Dec 24 -- merged-usr layout; everything goes in /usr/bin now
  for i in ${bin_dyn_executables} ${bin_non_dyn_executables}
  do copy_one_part /bin/$i ${SOURCES_DIR}/usr/bin/; done
  # /sbin
  for i in ${sbin_dyn_executables} ${sbin_non_dyn_executables}
  do copy_one_part /sbin/$i ${SOURCES_DIR}/usr/bin/; done
  # /usr/bin
  for i in ${usr_bin_dyn_executables} ${usr_bin_non_dyn_executables}
  do copy_one_part /usr/bin/$i ${SOURCES_DIR}/usr/bin/; done

  if [ "${init_splash}" == "yes" ]
  then copy_one_part /sbin/fbcondecor_helper ${SOURCES_DIR}/usr/bin/
  else d_message "Skipping copy for /sbin/fbcondecor_helper... (splash not requested)" 2
  fi
  copy_one_part ./init ${SOURCES_DIR}/

  # copy config file
  copy_one_part ${config_file} ${SOURCES_DIR}/

  # copy admin files
  d_message "Copying necessary admin files..." 1
  for i in $admin_files
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
  # create symlinks - updated 27 Dec 24 with merged-usr layout; everything goes in /usr/bin
  d_message "Creating busybox links in initramfs/bin/ ..." 1
  cd ${SOURCES_DIR}/usr/bin/
  for i in $busybox_link_list
  do d_message_n "Linking:   ${LBon}$i${Boff} --> ${BGon}busybox${Boff} ..." 2;
  ln -s busybox "$i" ; d_right_status $? 2; done

  # create symlinks in /sbin - updated 27 Dec 24 with merged-usr layout; everything goes in /usr/bin
  d_message "Creating lvm2 links in initramfs/sbin/ ..." 1
  cd ${SOURCES_DIR}/usr/bin/
  for i in $lvm_link_list
  do d_message_n "Linking:   ${LBon}$i${Boff} --> ${BGon}lvm${Boff} ..." 2;
  ln -s lvm "$i" ; d_right_status $? 2; done
  for i in $e2fsck_link_list
  do d_message_n "Linking:   ${LBon}$i${Boff} --> ${BGon}e2fsck${Boff} ..." 2;
  ln -s e2fsck "$i" ; d_right_status $? 2; done
  #splash_helper -> //sbin/fbcondecor_helper - updated 27 Dec 24 with merged-usr layout; everything goes in /usr/bin
  if [ "${init_splash}" == "yes" ]
  then d_message_n "Linking:   ${LBon}splash_helper${Boff} --> ${BGon}//sbin/fbcondecor_helper${Boff} ..." 2;
    ln -s //usr/bin/fbcondecor_helper splash_helper ; d_right_status $? 2
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

build_other_devices()
{
  # used to also build block device nodes, now just the console character dev
  old_dir=$(pwd)
  cd ${SOURCES_DIR}
  d_message "Changed from ${old_dir} to SOURCES_DIR: $(pwd)" 2
  
  # build console character device
  mknod -m 600 console c 5 1

  cd ${old_dir}
  d_message "Changed from SOURCES_DIR: ${SOURCES_DIR} tp old_dir: $(pwd)" 2
}

build_merged-usr_dir_tree_links()
{
  # get target and links to it
  local targets=('')
  local links=('')
  source ${MAKE_DIR}/initramfs_merged-usr_dir_links
  old_dir=$(pwd)
  cd ${SOURCES_DIR}
  d_message "Changed from ${old_dir} to SOURCES_DIR: $(pwd)" 2
  for ((i=0; i<${#links[@]}; i++))
  do
    # if this link doesn't exist, create it
    if [ ! -L ${links[$i]} ]
    then
      d_message_n " Creating link ${LBon}${links[$i]}${Boff} --> ${BGon}${targets[$i]}${Boff} ..." 2
      ln -s ${targets[$i]} ${links[$i]}; d_right_status $? 2
    else
      found_target="echo $(stat ${links[$i]} | head -n1 | cut -d'>' -f2)"
      d_message_n " Found existing link ${SOURCES_DIR}${links[$i]} --> ${found_target} ..." 2; d_right_status $? 2
    fi
  done
  cd ${old_dir}
  d_message "Changed from SOURCES_DIR: ${SOURCES_DIR} tp old_dir: $(pwd)" 2
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
        # create target directory if it diesn't already exist
        d_message "  about to execute: [[ ! -e ${SOURCES_DIR}${dir_name} ]] && mkdir -p ${SOURCES_DIR}${dir_name}" 3
        [[ ! -e ${SOURCES_DIR}${dir_name} ]] && mkdir -p ${SOURCES_DIR}${dir_name}
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
        # create target directory if it diesn't already exist
        d_message "  about to execute: [[ ! -e ${SOURCES_DIR}${dir_name} ]] && mkdir -p ${SOURCES_DIR}${dir_name}" 3
        [[ ! -e ${SOURCES_DIR}${dir_name} ]] && mkdir -p ${SOURCES_DIR}${dir_name}
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

  # address rare issue with error "libgcc_s.so.1 must be installed for pthread_cancel to work"
  # occurs when cryptsetup tries to open LUKS volume - see references (similar but different) --
  #   https://bugs.gentoo.org/760249 (resolved by fix to dracut)
  #   https://forums.gentoo.org/viewtopic-t-1096804-start-0.html (zfs problem. fix: copy file to initramfs)
  #   https://forums.gentoo.org/viewtopic-t-1049468-start-0.html (also zfs problem. same fix)
  # at least for now, I'm using the same fix here --

  # ( if needed, find and copy the missing file to /lib64/libgcc_s.so.1
  #   - then copy it to ${SOURCES_DIR}. Note: in this initramfs, /lib64 is a symlink to /lib )
  if [[ ! -e /lib64/libgcc_s.so.1 ]]
  then
    selector=$(gcc -v 2>&1 | grep Target | cut -d' ' -f2)
    searched_file="$( find /usr/ -iname libgcc_s.so.1 2>/dev/null | grep -v 32 | grep ${selector})"
    cp -v "${searched_file}" /lib64/libgcc_s.so.1
  fi
  missing_file=/lib64/libgcc_s.so.1
  target_name=$(basename ${missing_file})
  dir_name=$(dirname ${missing_file})

  d_message "  about to copy missing file [ ${missing_file} ] to ${SOURCES_DIR}${dir_name}/$target_name "
  [[ ! -e ${SOURCES_DIR}${dir_name}/${target_name} ]] && \
     copy_one_part "${dir_name}/${target_name}" "${SOURCES_DIR}${dir_name}/"

}

#---[ Main Script ]-------------------------------------------------------
# Create the required directory structure -- maintain the file
#   ${MAKE_DIR}/initramfs_dir_tree to tailor this
separator "Make Sources"  "mkinitramfs-$BUILD"
checkroot
display_config
# determine if splash is requested in init.conf
eval $(grep "splash" ${config_file} | grep -v "#")
[ "${init_splash}" == "yes" ] && d_message "splash requested" 1 || d_message "splash not requested" 1

separator "Build directory tree, device nodes, and links"  "mkinitramfs-$BUILD"
build_dir_tree
build_other_devices
build_merged-usr_dir_tree_links

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
