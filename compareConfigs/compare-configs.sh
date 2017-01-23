#!/bin/bash
#
# compare-configs
# for each line in file 1,
#     find the same config value in file 2
#         if the values are not the same, then display file1-val <tab> file2-val

source /usr/local/sbin/script_header_brendlefly

BUILD="0.1"

#INCLUDE_SAME="yes"
INCLUDE_SAME="no"
#DEBUG="true"
DEBUG="false"
#DEBUG2="true"
DEBUG2="false"
#DEBUG3="true"
DEBUG3="false"

out_file="compare-config-output"
width=$(termwidth)

#---[ local functions ]----------------
sanitycheck()
{
  [ "$#" -ne "2" ] && E_message "2 and only 2 args allowed, you sent [ $# ]" && exit 1
  if [ -f "$1" ]; then file1="$1"; message "file1: $file1"; else E_message "file1: [$1] does not exist"; exit 1; fi
  if [ -f "$2" ]; then file2="$2"; message "file2: $file2"; else E_message "file2: [$2] does not exist"; exit 1; fi
}

count_lines()  # in file specified by $1
{
  local count=0
  while read file1_line; do let "count++"; done < $1
  message "[will read $count lines from $1]\n"
  return $i
}

#---[ main script ]-----------
checkroot
sanitycheck $*
separator "compare-configs" "kernel-analysis"
echo
count_lines $file1
file1_length=$?
count_lines $file2
file2_length=$?
echo
SCP  # save cursor position

message "${BYon}Value_Compare${Boff} ${LBon}$file1 ${BRon}$file2${Boff}" > $out_file

# for each line in file 1,
i=0
while read file1_line
do
  # 3 cases,
  #  (1) leading "#" but blank or otherwise does not containg a "CONFIG_" setting (ignore)
  #  (2) leading "#" and contains a "CONFIG_" that "is not set"
  #  (3) "CONFIG_" is set with "=" to one of [y|n|m] or another value
  let "i++"
  SKIP2="false"
  [ "$DEBUG" == "true" ] && message "file1_line: $file1_line"
  if [[ "${file1_line:0:1}" == "#" ]]
  then # case (1) or (2)
    if [[ ! "${file1_line:2:6}" == "CONFIG" ]]
    then # case (1) -- just a comment; ignore it
      SKIP2="true"
      [ "$DEBUG" == "true" ] && message ">>> ${BRon}case (1) [ignoring comment]${Boff}   target1: $target1  value1: $value1"
    else # case (2) -- value1 is "is not set"
      target1="$( echo ${file1_line} | cut -d' ' -f2 )"
      value1="is not set"
      [ "$DEBUG" == "true" ] && message ">>> ${BRon}case (2) [is not set]${Boff}   target1: $target1  value1: $value1"
    fi
  else # case (3) -- extract value1 after the "="
    idx=$(( $(expr index "$file1_line" "=") -1 ))
    [ "$DEBUG" == "true" ] && message "idx: $idx"
    if [ "$idx" -ge "0" ]
    then # just checking for bad line to ignore
      target1="${file1_line:0:${idx}}"
      value1="${file1_line:$(( ${idx} + 1 )):$(( ${#file1_line} - ${idx} ))}"
      [ "$DEBUG" == "true" ] && message ">>> ${BGon}case (3a) [=]${Boff}   target1: $target1  value1: $value1"
    else # no "#" and no "=" --> bad line
      [ "$DEBUG2" == "true" ] && message "idx: $idx (blank line?)"
      SKIP2="true"
      [ "$DEBUG" == "true" ] && message ">>> ${BGon}case (3b) [=]${Boff}   target1: $target1  value1: $value1"
    fi
  fi
  [ "$DEBUG" == "true" ] && [ ! "$SKIP2" == "true" ] && \
    message "Looking in [$file2] for [$target1]"

  # if properly formatted file1_line, find the same config value in file 2
  if [ ! "$SKIP2" == "true" ]
  then
    j=0
    FOUND2="false"
    while read file2_line
    do
      let "j++"
      if [[ "${file2_line:0:1}" == "#" ]]
      then # case (1) or (2)
        if [[ ! "${file2_line:2:6}" == "CONFIG" ]]
        then # case (1) -- ignore it
          :
        else # case (2) -- value2 is "is not set"
          target2="$( echo ${file2_line} | cut -d' ' -f2 )"
          value2="is not set"
        fi
      else # case (3) -- extract value2 after the "="
        idx=$(( $(expr index "$file2_line" "=") -1 ))
        [ "$DEBUG2" == "true" ] && message "idx: $idx"
        if [ "$idx" -ge "0" ]
        then # just checking for bad line to ignore
          target2="${file2_line:0:${idx}}"
          value2="${file2_line:$(( ${idx} + 1 )):$(( ${#file2_line} - ${idx} ))}"
        else # no "#" and no "=" --> bad line
          [ "$DEBUG2" == "true" ] && message "idx: $idx (blank line?)"
        fi
        [ "$DEBUG2" == "true" ] && message ">>> ${BGon}case (3) [=]${Boff}   target2: $target2  value2: $value2"
      fi

      if [ "$target2" == "$target1" ]
      then  # found the right line in file 2, so we're done.
        FOUND2="true"
        #check if the values DIFFER (ignore if they are the same)
        if [ ! "$value2" == "$value1" ]
        then
          # **** this is the real comparative output *****
          message "${BYon}${target1}${Boff} ${LBon}[$value1] ${BRon}[$value2]${Boff}" >> $out_file
        else
          [ "$INCLUDE_SAME" == "yes" ] && message "${BYon}${target1}${Boff} ${BMon}Both = [${value2}]${Boff}" >> $out_file
        fi
      else
        [ "$DEBUG3" == "true" ] && message ">>> ${BRon}[No match: $target2]${Boff}"
      fi
      # restore cursor position, blank the line, and update the status
      RCP
      echo -en $(repeat " " $width )
      RCP
      echo -en "Status:\t$file1 $i/$file1_length\t$file2 $j/$file2_length"
    done < $file2
  fi

  if [ ! "$SKIP2" == "true" ] && [ ! "$FOUND2" == "true" ] # was really looking, but didn't find it
  then
    if [ "$value1" == "is not set" ]
    then # treat not found as a match for "is not set"
      FOUND2="true"
      [ "$DEBUG3" == "true" ] && message ">>> ${BYon}${target1}${Boff} ${LBon}[$value1] ${BRon}[NOT FOUND]${Boff}" | column -t
    else # really not found
      message "${BYon}${target1}${Boff} ${LBon}[$value1] ${BRon}[NOT FOUND]${Boff}"
    fi
  fi

done < $file1
