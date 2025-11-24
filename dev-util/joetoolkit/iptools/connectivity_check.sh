#!/bin/bash
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_unicode

PN=$(basename $0)

targets=(nuthuvia gmki92 sandbox raspicm46401 lcsp6402 rock5c6403 elrond google.com)

show_result() {
  echo -e -n "${BWon}result: [${Mon}$1${BWon}] ${Boff}"
  if [ $1 -eq 0 ] ; then
    bremoji $face_beam
    echo -e "${BGon}Success${Boff}"
  else
    bremoji $no_entry
    echo -e "${BRon}Failed${Boff}"
  fi
}

for x in "${targets[@]}"; do
  separator "${PN}" "(${x})"
  message "${BYon}pinging ${LBon}-4 ${BMon}${x}${Boff}"
  ping -4 -c3 -w5 "$x"
  show_result $?

  if [[ "$x" == "google.com" ]] ; then
    message "${BYon}pinging ${LBon}-6 ${BMon}${x}${Boff}"
    ping -6 -c3 -w5 "$x"
    show_result $?
  else
    message "${BYon}pinging ${LBon}-6 ${BMon}${x}.brendler${Boff}"
    ping -6 -c3 -w5 "$x.brendler"
    show_result $?
  fi
done

