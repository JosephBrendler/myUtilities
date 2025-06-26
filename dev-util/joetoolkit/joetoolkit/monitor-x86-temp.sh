#!/bin/bash

source /usr/sbin/script_header_joetoo
BUILD=0.1
TEMP=""
col2=40
tempfile=/home/joe/temp
temprow=3
clockrow=6
voltsrow=20
memrow=27
versionrow=32
wait_time=1

c_to_f() {
  tc="$1"
  tf=$(echo "scale=2;((9/5) * $tc) + 32" |bc)
  echo $tc\°C \($tf\°F\)
}

measure_cpu_temp() {
  CUP $((${temprow}+1)) 1
  cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
  f_cpu_temp="${cpu_temp:0:2}.${cpu_temp:2:2}"
  message_n "${LBon}CPU Temp:${Boff} $(c_to_f ${f_cpu_temp})"
}

#-----[ start of main script ]----------------------------------
CLR; CUP 1 1
separator "monitor-x86-temp.sh-$BUILD"
echo
HCU
while [ ${TRUE} ]
do
  measure_cpu_temp
  sleep ${wait_time}
done
SCU
