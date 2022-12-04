#!/bin/bash
# migrate_layman_to_eselect-repository.sh       -- Joe Brendler 17 November 2019
# issue the sequence of commands that accomplishes this migration
source /usr/local/sbin/script_header_brendlefly
BUILD="0.01a"

command_sequence=(
'layman -d joetoo'
'layman -d gentoo'
'layman -d kde'
'layman -l'
'layman -d crossdev'
'emerge -C layman'
'eix-update'
'rm /etc/portage/repos.conf/layman.conf'
'rm -r /var/lib/layman/'
'emerge -av eselect-repository'
'eselect repository list -i'
'eselect repository enable crossdev kde'
'eselect repository add joetoo git https://github.com/JosephBrendler/joetoo.git'
'eix-sync'
'eix-update'
'eix --in-overlay joetoo'
)

#-----[ functions ]--------------------------------------------------

#-----[ main script ]------------------------------------------------
separator "migrate_layman_to_eselect-repository.sh-${BUILD}"

answer=""
prompt "${BWon}Are you ready to run ${BYon}migrate_layman_to_eselect-repository.sh?${Boff}?"
[[ ! $answer == [Yy] ]] && exit
for ((i=0; i<${#command_sequence[@]}; i++))
do
  answer=""
  prompt "${LBon}Are you ready to run \"${BYon}${command_sequence[i]}${LBon}\"?${Boff}"
  if [[ $answer == [Yy] ]]
  then
    message_n "${BRon}About to run \"${BGon}${command_sequence[i]}${LBon}\"...${Boff}"
    eval ${command_sequence[i]}; right_status $?
  else
    message "Not running \"${command_sequence[i]}\". Quitting..." && exit
  fi
done
