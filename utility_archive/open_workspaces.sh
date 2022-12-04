#!/bin/bash
# open_workspaces.sh -- joe brendler -- 2 Oct 16
# script to open lxterminal sessions on each of my kde workspaces (used for ssh sessions with servers)
# Note: this beta version mixes techniqes for window control from wmctrl, wmiface, and xdotool
# TODO: a future version could do all of this with just xdotool, I think

source /usr/local/sbin/script_header_brendlefly
BUILD="0.011b 161023"
SYS_DATE="$(timestamp)"
logFile="/home/joe/open_workspaces.log"
let count=0
let dec=0
let hex=0x0
found="false"
let h_offset=20
let v_offset=10
let width=800
let height=950
sleepWait=0.1
DEBUG="true"
#DEBUG="false"

#num_desktops=$(wmiface numberOfDesktops)
num_desktops=10
original_window=$(wmiface activeWindow)

# define the ssh sessions to be employed by each of the terminals (a pair per workspace)
#  Note: disable the ssh session by leading with "x"
ssh_session=(dummy_zero_entry \
             x_thuvia x_thuvia \
             raspberry201 192.168.63.6 \
             x_raspberry03 raspberry06 \
             selene x_selene \
             oromis persephone \
             pascal cantor \
             euler x_finwe \
             slim slim2 \
             spartacus zelda
             x_thuvia )
#             raspberry201 x_raspberry202 \

[ "${DEBUG}" == "true" ] && message "(DEBUG $(timestamp)) Top of script. Just set global variables."

#-----[ begin functions ]-----------------------------------------------------
checkNOTroot()     # Run as root, of course.
{
  if [ "$UID" == "$ROOT_UID" ]; then E_message "Must be in USER mode (not root) to run this script"; echo; exit 1; else return 0; fi
}


show_config() {
  message "${LBon}BUILD..........:${Boff} ${BUILD}"
  message "${LBon}SYS_DATE.......:${Boff} $(timestamp)"
  message "${LBon}logFile........:${Boff} ${logFile}"
  message "${LBon}count..........:${Boff} ${count}"
  message "${LBon}dec............:${Boff} ${dec}"
  message "${LBon}hex............:${Boff} ${hex}"
  message "${LBon}found..........:${Boff} ${found}"
  message "${LBon}h_offset.......:${Boff} ${h_offset}"
  message "${LBon}v_offset.......:${Boff} ${v_offset}"
  message "${LBon}width..........:${Boff} ${width}"
  message "${LBon}height.........:${Boff} ${height}"
  message "${LBon}sleepWait......:${Boff} ${sleepWait}"
  message "${LBon}DEBUG..........:${Boff} ${DEBUG}"
  message "${LBon}num_desktops...:${Boff} ${num_desktops}"
  message "${LBon}original_window:${Boff} ${original_window}"
  echo
  message "${LBon}ssh_session[*]:${Boff} ${ssh_session[*]}"
  echo
}

close_terminals() {
# close all previously-opened terminals (lxterminal or Konsole)
for x in \
  $(wmiface findNormalWindows "" "lxterminal" "" "" "" false; \
    wmiface findNormalWindows "" "Konsole" "" "" "" false)
do
  if [ ! "$x" == "$(wmiface activeWindow)" ]
  then # does not match active terminal
    wmiface closeWindow $x
  else # matches active terminal
    hex="0x0$(printf '%x\n' $x)"
    message "$(timestamp) left open window: ${x} [hex ${hex}]"
    message "$(timestamp) caption.........: $(wmiface caption $x)"
    message "$(timestamp) windowClass.....: $(wmiface windowClass $x)"
  fi
done
}

initialize_terminal_array() {
  for i in $(seq 1 100)
  do
    terminal[$i]=""
  done
  let count=0
  [ "${DEBUG}" == "true" ] && message "(DEBUG $(timestamp)) terminal[${i}] initialized"
}

load_terminal_array() {
# for all terminals (lxterminal or konsole),
#    put an element in the array.
# count the number of elements
let count=0
for x in \
  $(wmiface findNormalWindows "" "lxterminal" "" "" "" false; \
    wmiface findNormalWindows "" "Konsole" "" "" "" false)
do

  let count++
  terminal[$count]=$x
  [ "${DEBUG}" == "true" ] && message "(DEBUG $(timestamp) - load_terminal_array) I just set terminal[${count}] = ${x}"
done
}

get_new_terminal_window_number() {
# for all window numbers, check to see if the number is already in the array,
#  if it's not, then add it and return the new window number
for x in \
  $(wmiface findNormalWindows "" "lxterminal" "" "" "" false; \
    wmiface findNormalWindows "" "Konsole" "" "" "" false)
do
  found="false"
  check_not_in_array $x
  if [ "$found" == "false" ]
  then
    let dec=$x
    return $x
  else
    return -1
  fi
done
}

check_not_in_array() {
# leave found="false" and return 1 if not already in array (after adding it)
# set found="true" and return 0 if alreay in array
entry=$1
for i in $(seq 1 $count)
do
  if [ "$entry" == "$terminal[$i]" ]
  then # already in array; return 0
    found="true"
    return 0
  fi
done

# got this far only if 1-count are not a match, so add it
if [ "$found" == "false" ]
then
  let count++
  terminal[$count]=$entry
  [ "${DEBUG}" == "true" ] && message "(DEBUG $(timestamp) - check_not_in_array) I just set terminal[${count}] = ${entry}"
fi
return 1
}

print_ssh_session_array() {
  #used for debugging only
  for i in $(seq 1 $num_desktops)
  do
    let index=$(( $((2 * $i)) - 1 ))
    cmd_target=${ssh_session[$index]}
    message "$(timestamp) debug ssh_session_array: i=$i index=$index ssh_session[\$index]=${ssh_session[$index]} cmd_target=$cmd_target"
    let index=$(( 2 * $i ))
    cmd_target=${ssh_session[$index]}
    message "$(timestamp) debug ssh_session_array: i=$i index=$index ssh_session[\$index]=${ssh_session[$index]} cmd_target=$cmd_target"
  done
}

#--------[ start main script ]-------------------------------------
checkNOTroot
separator "open_workspaces.sh-$BUILD" >> $logFile

message "Openning lxterminals and starting ssh sessions. Please wait..."
exec 6>&1 2>/dev/null           # Link file descriptor #6 with stdout. Saves stdout.
exec > $logFile  2>/dev/null    # stdout replaced with file.
# ----------------------------------------------------------- #
# All output from commands in this block sent to file $logFile

[ "${DEBUG}" == "true" ] && show_config
close_terminals
message "$(timestamp) done closing"

initialize_terminal_array
message "$(timestamp) initialized"

load_terminal_array
message "$(timestamp) count = [$count]"

#initialize keychain to enable openning ssh sessions in new terminals
/usr/bin/keychain ~/.ssh/id_ecdsa
/usr/bin/keychain ~/.ssh/id_rsa
# source environment variables from <hostname>-sh
source ~/.keychain/Thuvia-sh > /dev/null
#eval `keychain --eval id_ecdsa`
#eval `keychain --eval id_rsa`

# uncomment to debug
#print_ssh_session_array
#return 0

# set number of desktops
wmctrl -n $num_desktops

# open up to two lxterminals on each of my desktops (workspaces), save some space for my browser and email, etc
for DT in $(seq 1 $num_desktops)
do
# open an lxterminal and start an ssh command if not disabled (see ssh_session array above)
  let index=$(( $((2 * $DT)) - 1 ))
  cmd_target=${ssh_session[$index]}
  message "$(timestamp) index = [$index] , cmd_target = $cmd_target"
  [ "${cmd_target:0:1}" != "x" ] && cmd="--command ssh $cmd_target" || cmd=""
  message "$(timestamp) about to run \"lxterminal --title=\"lxterminal_$DT.1\" $cmd &\""
  lxterminal --title="lxterminal_$DT.1" 2>/dev/null &
  sleep $sleepWait
  get_new_terminal_window_number   # is returned as $dec
  hex="0x0$(printf '%x\n' $dec)"
  message "$(timestamp) openned new terminal_win = [$dec, $hex]"
  [ ! -z "$cmd" ] && xdotool type --window $dec "ssh $cmd_target"
  sleep $sleepWait
  wmctrl -i -r $hex -T "lxterminal_$DT.1"
  sleep $sleepWait
  # move the new window to desktop #DT
  wmiface setWindowDesktop $dec $DT && \
    message "$(timestamp) moved window $dec to desktop $DT" || \
    message "${BRon}Error in moving window $dec to desktop $DT ${Boff}"
  wmiface forceActiveWindow $dec
  [ ! -z "$cmd" ] && xdotool key --window $dec KP_Enter
  let x_pos=$h_offset; let y_pos=$v_offset
  wmiface setFrameGeometry $dec $x_pos $y_pos $width $height
  message "$(timestamp) set geometry for window $dec to [x: $x_pos, y: $y_pos, w: $width, h: $height]"
  wmiface forceActiveWindow $original_window
  sleep $sleepWait


  let index=$(( 2 * $DT ))
  cmd_target=${ssh_session[$index]}
  message "$(timestamp) index = [$index] , cmd_target = $cmd_target"
  [ "${cmd_target:0:1}" != "x" ] && cmd="--command ssh $cmd_target" || cmd=""
  message "$(timestamp) about to run \"lxterminal --title=\"lxterminal_$DT.2\" $cmd &\""
  lxterminal --title="lxterminal_$DT.2" 2>/dev/null &
  sleep $sleepWait
  get_new_terminal_window_number   # is returned as $dec
  hex="0x0$(printf '%x\n' $dec)"
  message "$(timestamp) openned new terminal_win = [$dec, $hex]"
  [ ! -z "$cmd" ] && xdotool type --window $dec "ssh $cmd_target"
  sleep $sleepWait
  wmctrl -i -r $hex -T "lxterminal_$DT.2"
  sleep $sleepWait
  # move the new window to desktop #DT
  wmiface setWindowDesktop $dec $DT
  message "$(timestamp) moved window $dec to desktop $DT"
  wmiface forceActiveWindow $dec
  [ ! -z "$cmd" ] && xdotool key --window $dec KP_Enter
  let x_pos=$(( $h_offset + $width + h_offset )); let y_pos=$v_offset
  wmiface setFrameGeometry $dec $x_pos $y_pos $width $height
  message "$(timestamp) set geometry for window $dec to [x: $x_pos, y: $y_pos, w: $width, h: $height]"
  wmiface forceActiveWindow $original_window
  sleep $sleepWait
done
# ----------------------------------------------------------- #
exec 1>&6 6>&-  2>/dev/null     # Restore stdout and close file descriptor #6.

cat $logFile
wmiface setCurrentDesktop 1
