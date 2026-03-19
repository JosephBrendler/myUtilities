#!/bin/bash
# enumerate_windowsl.sh -- joe brendler -- 2 Oct 16
# use the wmiface utility to enumerate my windows and
#  the properties thereof

source /usr/sbin/script_header_joetoo

for x in $(wmiface findNormalWindows "" "" "" "" "" false)
do
  [ "$x" == "$(wmiface activeWindow)" ] && match="true" || match="false"
  separator $x "Window"
  message "${LBon}caption..........:${Boff} $(wmiface caption $x)"
  message "${LBon}activeWindow.....:${Boff} $(wmiface activeWindow)"
  message "${LBon}matchActiveWindow:${Boff} $match"
  message "${LBon}windowClass......:${Boff} $(wmiface windowClass $x)"
  message "${LBon}windowRole.......:${Boff} $(wmiface windowRole $x)"
  message "${LBon}windowHostname...:${Boff} $(wmiface windowHostname $x)"
  message "${LBon}pid..............:${Boff} $(wmiface pid $x)"
  message "${LBon}windowDesktop....:${Boff} $(wmiface windowDesktop $x)"
  message "${LBon}frameGeometry....:${Boff} $(wmiface frameGeometry $x)"
  message "${LBon}windowGeometry...:${Boff} $(wmiface windowGeometry $x)"
  message "${LBon}frameSize........:${Boff} $(wmiface frameSize $x)"
  message "${LBon}windowSize.......:${Boff} $(wmiface windowSize $x)"
  message "${LBon}framePosition....:${Boff} $(wmiface framePosition $x)"
  message "${LBon}windowPosition...:${Boff} $(wmiface windowPosition $x)"
  message "${LBon}windowFullScreen.:${Boff} $(wmiface windowFullScreen $x)"
  message "${LBon}keptAbove........:${Boff} $(wmiface keptAbove $x)"
  message "${LBon}keptBelow........:${Boff} $(wmiface keptBelow $x)"
  message "${LBon}windowShaded.....:${Boff} $(wmiface windowShaded $x)"
  message "${LBon}windowMaximized..:${Boff} $(wmiface windowMaximized $x)"
  message "${LBon}minimized........:${Boff} $(wmiface minimized $x)"
done
