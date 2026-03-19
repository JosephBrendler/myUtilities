#!/bin/bash
source /usr/local/sbin/script_header_joe_brendler
BUILD=0.0a

separator "heartbeat-$BUILD"

CLR
CUP 2 1
SCP
count=0
while [ 1 ]
do
  RCP
  case $(( $count % 2 )) in
    0 )
      echo -en "     I am ${BRon}alive${Boff}";;
    1 )
      echo -en "     I am ${BYon}ALIVE${Boff}";;
  esac
  let count++
  sleep 1
done
