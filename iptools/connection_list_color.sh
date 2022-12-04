#!/bin/bash
# connecton_list_color.sh
# joe brendler
# 10 Apr 16

#---[ local variables ]---------------------------
source /usr/local/sbin/script_header_brendlefly
BUILD=0.0.1
#target=/proc/net/ip_conntrack
target=/proc/net/nf_conntrack
array=('')

#---[ functions ]---------------------------------
set_colors() {
BLACK="30"     # foreground black
RED="31"       # foreground red
GREEN="32"     # foreground green
YELLOW="33"    # foreground yellow
BLUE="34"      # foreground blue
MAG="35"       # foreground magenta (it's like fucia)
LBLUE="36"     # foreground light blue (cyan)
WHITE="37"     # foreground white (cyan)
#---[ Set Background Color ]---------------------------------------
BACKoff="40"   # background black
RBACK="41"     # background red
GBACK="42"     # background green
YBACK="43"     # background yellow
BBACK="44"     # background blue
MBACK="45"     # background magenta
LBACK="46"     # background light blue (cyan)
WBACK="47"     # background white
HWBACK="107"   # background high intensity white
}

farb() {
  # even or odd line (for formatting)
  local evenodd="$1"
  local f_num="$2"

  case "$evenodd" in
    "0") # even
         b_clr="${WBACK}";
         case "$f_num" in
           "1") f_clr=${BLUE};;
           "2") f_clr=${BLACK};;
           "3") f_clr=${BLACK};;
           "4") f_clr=${GREEN};;
             *) ;;
         esac;;
    "1") # odd
         b_clr="${HWBACK}";
         case "$f_num" in
           "1") f_clr=${BLUE};;
           "2") f_clr=${BLACK};;
           "3") f_clr=${BLACK};;
           "4") f_clr=${GREEN};;
             *) ;;
         esac;;
      *) #error
         ;;
  esac
  echo "$(color "$f_clr" "$b_clr" $FALSE)"
}

#---[ main script ]---------------------------------
separator "connection_list-${BUILD}"
checkroot
set_colors

#read count of connections and ip into array
linecounter=1
while IFS=' ' read -a array
do
  # even or odd line
  eo="$(( $linecounter % 2 ))"
  # assign from array
  count=${array[0]};   ip=${array[1]}
  connector="connections to "
  # start each output message with "[ nnn ] connections to ww.xx.yy.zz"
  msg="$(farb $eo 1)[ $(farb $eo 2)${count}$(farb $eo 1) ]"
  msg+=" $(farb $eo 3)${connector}$(farb $eo 1)${ip}"
  msglen=$((5 + ${#count} + ${#connector} + ${#ip}))
  spaces=$(( $(tput cols) - ${msglen} ))
  for ((i=0; i<${spaces}; i++)); do msg+=" "; done
  # concatenate next line with look up the ip in whois database
  msg+="\n$(farb $eo 2)$(whois ${ip} 2>/dev/null | grep Organization | cut -d':' -f2 | sed 's/^ *//' )"
  # concatenate same line with geolocation of the ip; indent line(s) 6 spaces
  msg2=" [ $(geoiplookup ${ip} 2>/dev/null | \
        grep -v 'GeoIP Country Edition:' | grep -v 'GeoIP ASNum Edition:' | \
        sed 's/GeoIP City Edition, Rev 1: //' | \
        sed 's/^ *//' ) ]"
  msglen=${#msg2}
  spaces=$(( $(tput cols) - ${msglen} ))
  msg+="$(farb $eo 1)${msg2}"
  for ((i=0; i<${spaces}; i++)); do msg+=" "; done
  msg+="${Boff}"
  # output the message
  echo -e "${msg}"
  (( linecounter++  ))
     # read input from target file [/proc/net/nf_conntrack]; count number of connections to each unique dest ip
done <<< $(grep -v "sport=53" ${target} | cut -d'=' -f3 | cut -d' ' -f1 | sort | uniq -c | sort -bn | sed 's/^ *//')

