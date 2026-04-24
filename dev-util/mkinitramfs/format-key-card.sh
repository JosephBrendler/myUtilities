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
  # correct # of arguments?
  if [[ ! $# -eq 1 ]]; then
    j_msg -${err} "Error: only one argument (device spec) allowed, you gave $#"
    exit
  else
    # specifies a valid block device?
    if [ -b "$1" ]; then
      separator "${PN}-${BUILD}"
      j_msg -${notice} -p "formatting device: $1..."
    else
      j_msg -${err} "Error: invalid block device [ $1 ]"
      exit
    fi  # blkdev?
  fi  # args?
}

format_card()
{
  # format device specified by argument $1, giving it a random UUID
  local _fc_device="$1"
  local _fc_uuid=$(perl -e 'printf "0x%04X%04X\n", rand 0xFFFF, rand 0xFFFF')
  # define command array
  local _fc_command=(mkfs.vfat -cv -nKEY -M0xf8 -i"${my_uuid}" -F32 "${_fc_device}")
  j_msg -${notice} -p "About to execute command: [ ${_fc_command[@]} ]"
  j_msg -${notice} -p "${BYon}Are you sure? ${Boff}"
  confirm_continue_or_exit
  j_msg -${notice} -p -n "formatting"
  # execute the array
  "${_fc_command[@]}"
  right_status $? ${notice}
}

copy_crypt_dat()
{
  # copy crypto key to device specified by argument $1
  j_msg -${notice} -p "Would you like to load keyfile to the device?"
  confirm_continue_or_exit
  # create mountpoint if needed
  if [ ! -d "/mnt/KEY" ]; then
    j_msg -${notice} -p -n "Creating mountpoint /mnt/KEY"
    mkdir -p /mnt/KEY
    right_status $? ${notice}
  fi
  j_msg -${notice} -p -n "Mounting $1 on /mnt/KEY"
  mount $1 /mnt/KEY; right_status $? ${notice}
  #create dir if needed
  if [ ! -d "/mnt/KEY/crypt"; then
    j_msg -${notice} -p -n "Creating keystore directory /mnt/KEY/crypt"
    mkdir -p /mnt/KEY/crypt; right_status $? ${notice}
  fi
  # copy file if needed
  if [ ! -f "/mnt/KEY/crypt/dat" ]; then
    j_msg -${notice} -p -n "Copying keyfile to /mnt/KEY/crypt/dat"
    answer="Y"
  else
    yns_prompt "/mnt/KEY/crypt/dat already exists.  Overwrite?"
  fi
  case "$answer" in
    [yY]*)
      j_msg -${notice} -p -n "copying crypt/dat to /mnt/KEY/crypt"
      cp crypt/dat /mnt/KEY/crypt/; right_status $? ${notice} ;;
    [nN]*) leave "aborting as requested" ;;
    *) die "invalid answer to overwrite prompt" ;;
  esac
}

#---[ main script ]-------------------------------------
checkroot
check_argument $*
format_card $1
copy_crypt_dat $1
echo
j_msg -${notice} -p "All done."
