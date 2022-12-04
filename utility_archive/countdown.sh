#!/bin/bash

#DEBUG="true"
DEBUG="false"

# count down seconds while waiting X seconds
countdown()   # argument: count-down seconds
{
  # store current minutes and seconds
  min=$(date +%M)
  sec=$(date +%S)
  [[ "${DEBUG}" == "true" ]] && message "min: $min"
  [[ "${DEBUG}" == "true" ]] && message "sec: $sec"
  wait_time=60  #default = 1 minute
  [[ ! -z $1 ]] && wait_time="$1"
  # if wait time is greater than 60 seconds, convert to minutes and seconds
  if [[ "${wait_time}" -ge "60" ]]
  then
    wait_min=$(( ${wait_time} / 60 ))
    wait_sec=$(( ${wait_time} % 60 ))
  else
    wait_min=0
    wait_sec=${wait_time}
  fi
  [[ "${DEBUG}" == "true" ]] && message "wait_min: $wait_min"
  [[ "${DEBUG}" == "true" ]] && message "wait_sec: $wait_sec"

  [[ "${DEBUG}" == "true" ]] && message "Waiting ${wait_time} seconds [${wait_min}:${wait_sec}] ..."
  [[ "${DEBUG}" == "true" ]] && message "  Started at $(date +%H:%M:%S)"
  # check for existence of block device matching passdevice specification
  tgt_min="$(( ${min} + ${wait_min} ))"
  tgt_sec="$(( ${sec} + ${wait_sec} ))"
  [[ "${DEBUG}" == "true" ]] && message "tgt_min: $tgt_min"
  [[ "${DEBUG}" == "true" ]] && message "tgt_sec: $tgt_sec"
  if [[ "${tgt_sec}" -ge "60" ]]
  then
    tgt_min="$(( ${tgt_min} + 1 ))"
    tgt_sec="$(( ${tgt_sec} % 60 ))"
  fi
  [[ "${DEBUG}" == "true" ]] && message "tgt_min: $tgt_min"
  [[ "${DEBUG}" == "true" ]] && message "tgt_sec: $tgt_sec"
  min="$(date +%M)"
  sec="$(date +%S)"
  rem="$(( $(( $(( $tgt_min * 60 )) + $tgt_sec )) - $(( $(( $min * 60 )) + $sec )) ))"
  while [[ "${rem}" -gt "0" ]]
  do
    echo -en "\r  "$(date +%H:%M:%S)
    sleep 0.1
    min="$(date +%M)"
    sec="$(date +%S)"
    [[ "${DEBUG}" == "true" ]] && echo -n "     min: $min, sec: $sec"
    rem="$(( $(( $(( $tgt_min * 60 )) + $tgt_sec )) - $(( $(( $min * 60 )) + $sec )) ))"
    echo -n "    $rem seconds left..."
  done
  echo -e "\n  Done"
}

source /usr/local/sbin/script_header_brendlefly
