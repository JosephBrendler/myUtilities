#!/bin/bash

while IFS='' read -r line
do
  arrayline=($line)
  leftside="-----["; rightside="]---------------------------------------"
  printf "%s %s %s\n" "$leftside" "$line" "$rightside"
  printf "   Is an array with [%d] elements.  As a string: \"%s\"\n" ${#arrayline[@]} "$line"
  echo "   About to run loop for i=0 to i=${#arrayline[@]}..."
  for ((i=0; i<${#arrayline[@]}; i++))
  do
    printf "      Element[%d] = \"%s\"\n" $i "${arrayline[i]}"
  done
echo
done < /home/joe/temp
