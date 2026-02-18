#!/bin/bash
# format-key-card.sh
# joe brendler 2 Jan 15
# format device specified by argument ($1) as 32bit FAT, of HDD media type (0xf8),
#   with label="KEY", and random UUID
source /usr/sbin/script_header_joetoo

BUILD="0.0.0 20150102"
DEBUG="$TRUE"
#DEBUG="$FALSE"

PN=${0##*/}

check_argument()
{
  if [[ ! $# -eq 1 ]] # correct # of arguments?
    then error_msg "Error: only one argument (device spec) allowed, you gave $#"
    exit
  else
    if [ -b "$1" ]  # specifies a valid block device?
    then
      separator "${PN}-${BUILD}"
      notice_msg "formatting device: $1..."
    else
      error_msg "Error: invalid block device [ $1 ]"
      exit
    fi
  fi
}

format_card()
{
  # format device specified by argument $1
  my_uuid=$(perl -e 'printf "0x%04X%04X\n", rand 0xFFFF, rand 0xFFFF')
  command="mkfs.vfat -cv -nKEY -M0xf8 -i$my_uuid -F32 $1"
  notice_msg "About to execute command: [ $command ]"
  notice_msg "${BYon}Are you sure? ${Boff}"
  confirm_continue_or_exit
  notice_msg_n "formatting"
  mkfs.vfat -cv -nKEY -M0xf8 -i"$my_uuid" -F32 "$1"
  right_status $?
}

copy_crypt_dat()
{
  # copy crypto key to device specified by argument $1
  notice_msg "Would you like to load keyfile to the device?"
  confirm_continue_or_exit
  # create mountpoint if needed
  if [ ! -d "/mnt/KEY" ]; then
    notice_msg_n "Creating mountpoint /mnt/KEY"
    mkdir /mnt/KEY
    right_status
  fi
  notice_msg_n "Mounting $1 on /mnt/KEY"
  mount $1 /mnt/KEY; right_status $?
  #create dir if needed
  if [ ! -d "/mnt/KEY/crypt"; then
    notice_msg_n "Creating keystore directory /mnt/KEY/crypt"
    mkdir /mnt/KEY/crypt; right_status $?
  fi
  # copy file if needed
  if [ ! -f "/mnt/KEY/crypt/dat" ]; then
    notice_msg_n "Copying keyfile to /mnt/KEY/crypt/dat"
    continue="Y"
  else
    yns_prompt "/mnt/KEY/crypt/dat already exists.  Overwrite?"
    case "$answer" in
      [yY]* )
        notice_msg_n "copying crypt/dat to /mnt/KEY/crypt"
        cp crypt/dat /mnt/KEY/crypt/; right_status $? ;;
      [nN]* ) leave "aborting as requested" ;;
      *     ) die "invalid answer to overwrite prompt" ;;
    esac
  fi
}

#---[ main script ]-------------------------------------
checkroot
check_argument $*
format_card $1
copy_crypt_dat $1
echo
notice_msg "All done."
