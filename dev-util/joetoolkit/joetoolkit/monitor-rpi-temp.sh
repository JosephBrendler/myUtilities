#!/bin/bash

source /usr/sbin/script_header_joetoo
BUILD=0.1a
TEMP=""
col2=40
tempfile=/home/joe/temp
vcgencmdfile=/usr/bin/vcgencmd
cputempfile=/sys/class/thermal/thermal_zone0/temp
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
  cpu_temp=$(cat ${cputempfile} 2>/dev/null)
  c_cpu_temp="${cpu_temp:0:2}.${cpu_temp:2:2}"
  message_n "${LBon}CPU Temp:${Boff} $(c_to_f ${c_cpu_temp})"
}

measure_gpu_temp() {
  CUP ${temprow} 1
  gpu_temp=$(echo $(${vcgencmdfile} measure_temp) | cut -d'=' -f2 | cut -d"'" -f1)
  gt1=$(echo ${gpu_temp} | cut -d'.' -f1)
  gt2=$(echo ${gpu_temp} | cut -d'.' -f2 | cut -c1)
  gt="${gt1}.${gt2}"
  SCP ; message_n "             "; RCP
  message_n "${LBon}GPU Temp:${Boff} $(c_to_f ${gt})"
}

measure_clock() {
  CUP ${clockrow} 1
  SCP; message "${LBon}Clock Frequencies (Hz):${Boff}"; RCP; CUD
  local row=${clockrow}
  for src in arm core h264 isp v3d uart pwm emmc pixel vec hdmi dpi
  do
    let "row++";  CUP ${row} 1
    message_n "$src:"
    CUP ${row} 11
    echo -e $(${vcgencmdfile} measure_clock $src) | sed 's/frequency//'
  done
}

measure_volts() {
  CUP ${voltsrow} 1
  message "${LBon}Core Voltages:${Boff}"
  local row=${voltsrow}
  for id in core sdram_c sdram_i sdram_p
  do
    let "row++";  CUP ${row} 1
    message_n "$id:"
    CUP ${row} 14
    echo -e $(${vcgencmdfile} measure_volts $id) | sed 's/volt=//'
  done
}

display_memory() {
  CUP ${memrow} 1
  message "${LBon}Memory Configuration:${Boff}"
  message "$(${vcgencmdfile} get_mem arm)"
  message "$(${vcgencmdfile} get_mem gpu)"
}

display_version() {
  CUP ${versionrow} 1
  message "${LBon}Version Information:${Boff}"
  local row=${versionrow}
  ${vcgencmdfile} version > ${tempfile}
  while read line
  do
    let "row++";  CUP ${row} 1
    message "$line"
  done < ${tempfile}
}

display_config() {
  CUP ${temprow} ${col2}
  message "${LBon}Configuration:${Boff}"
  local row=${temprow}
  local lines_of_config=($(${vcgencmdfile} get_config int))
  for ((i=0; i<${#lines_of_config[@]}; i++))
  do
    let "row++";  CUP ${row} ${col2}
    message_n "${lines_of_config[i]}"
  done
}

#-----[ start of main script ]----------------------------------
CLR; CUP 1 1
separator "monitor-rpi-temp.sh-$BUILD"
echo
HCU
while [ ${TRUE} ]
do
  measure_gpu_temp
  measure_cpu_temp
  measure_clock
  measure_volts
  display_memory
  display_version
  display_config
  sleep ${wait_time}
done
SCU
