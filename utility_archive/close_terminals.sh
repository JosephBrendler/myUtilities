#!/bin/bash
# close terminals.sh -- joe brendler -- 2 Oct 16
# use the wmiface utility to close all but the active
#   terminal (lxterminal or Konsole)

source /usr/local/sbin/script_header_brendlefly
BUILD="0.01b 161002"
#checkroot
separator "close_terminals.sh-$BUILD"
for x in \
  $(wmiface findNormalWindows "" "lxterminal" "" "" "" false; \
    wmiface findNormalWindows "" "Konsole" "" "" "" false)
do
  if [ ! "$x" == "$(wmiface activeWindow)" ]
  then # does not match active terminal
    wmiface closeWindow $x
  else # matches active terminal
    hex="0x0$(printf '%x\n' $x)"
    message "${LBon}left open window:${Boff} ${x} [hex ${hex}]"
    message "${LBon}caption.........:${Boff} $(wmiface caption $x)"
    message "${LBon}windowClass.....:${Boff} $(wmiface windowClass $x)"
  fi
done
