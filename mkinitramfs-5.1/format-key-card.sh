#!/bin/bash
# format-key-card.sh
# joe brendler 2 Jan 15
# format device specified by argument ($1) as 32bit FAT, of HDD media type (0xf8),
#   with label="KEY", and random UUID
source /usr/local/sbin/script_header_joe_brendler

BUILD="0.0.0 20150102"
DEBUG="true"
#DEBUG="false"

check_argument()
{
  if [[ ! $# -eq 1 ]] # correct # of arguments?
    then E_message "Error: only one argument (device spec) allowed, you gave $#"
    exit
  else
    if [ -b "$1" ]  # specifies a valid block device?
    then
      separator "format-key-card-${BUILD}"
      message "formatting device: $1..."
    else
      E_message "Error: invalid block device [ $1 ]"
      exit
    fi
  fi
}

ask_continue()
{
    # prompt to continue
    # YES = continue to next step, [nN] = stop now (stop now), anything else = ask again
    continue="x"
    while [[ ! "$continue" == [YnN] ]]
    do
        echo -en $BGon"*"$Boff" type UPPERCASE Y to confirm: " && \
        read continue && echo
        # if the response is "g" then set the GO_AHEAD flag and continue; if null apply default (y)
        [ "$DEBUG" == "true" ] && message "Debug: continue = [ ${continue} ]"
        case ${continue:0:1} in
            ""        ) continue="n" ;;
            "Y"       ) continue="Y" ;;
            "n" | "N" ) continue="n" ;;
            *         ) continue="x" ;;
        esac
    done
}

format_card()
{
  # format device specified by argument $1
  my_uuid=$(perl -e 'printf "0x%04X%04X\n", rand 0xFFFF, rand 0xFFFF')
  command="mkfs.vfat -cv -nKEY -M0xf8 -i$my_uuid -F32 $1"
  message "About to execute command: [ $command ]"
  message "${BYon}Are you sure? ${Boff}"
  ask_continue
  if [ "$continue" == "Y" ]
  then
    mkfs.vfat -cv -nKEY -M0xf8 -i$my_uuid -F32 $1 && message "Command completed successfully."
  else
    E_message "Command cancelled."
  fi
}

copy_crypt_dat()
{
  # copy crypto key to device specified by argument $1
  message "Would you like to load keyfile to the device?"
  ask_continue
  if [ "$continue" == "Y" ]
  then
    if [ ! -d "/mnt/KEY" ]  # create mountpoint if needed
    then
      message "Creating mountpoint /mnt/Key"
      mkdir /mnt/KEY
      [ ! $? -eq 0 ] && E_message "${BRon}failed${Boff}" && exit
      message "Ok"
    fi
    message "Mounting $1 on /mnt/KEY"
    mount $1 /mnt/KEY
    [ ! $? -eq 0 ] && E_message "${BRon}failed${Boff}" && exit
    message "Ok"
    if [ ! -d "/mnt/KEY/crypt" ]  #create dir if needed
    then
      message "Creating keystore directory /mnt/KEY/crypt"
      mkdir /mnt/KEY/crypt
      [ ! $? -eq 0 ] && E_message "${BRon}failed${Boff}" && exit
      message "Ok"
    fi
    if [ ! -f "/mnt/KEY/crypt/dat" ]  # copy file if needed
    then
      message "Copying keyfile to /mnt/KEY/crypt/dat"
      continue="Y"
    else
      message "/mnt/KEY/crypt/dat already exists.  Overwrite?"
      ask_continue
    fi
    if [ "$continue" == "Y" ]
    then
      message "copying crypt/dat to /mnt/KEY/crypt"
      cp crypt/dat /mnt/KEY/crypt/
      [ ! $? -eq 0 ] && E_message "${BRon}failed${Boff}" && exit
      message "Ok"
    fi
  else
    E_message "${BRon}Command cancelled.${Boff}"
    exit
  fi

}

#---[ main script ]-------------------------------------
checkroot
check_argument $*
format_card $1
copy_crypt_dat $1
echo
message "All done."
