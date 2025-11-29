#!/bin/bash
# strip_d_lines.sh  - parse the content of input file $1
# line for line, echo content but eliminate aty d_ "arg" statements
# assumes input comes from a "grep -n ',pattern>'" command so each line is numbered:
source /usr/sbin/script_header_joetoo

n=1
grep -v "#" $1 | while read full_line
do
    linenum="$(echo $full_line | cut -d':' -f1)"
    lineout="${linenum}: "
    line="$(echo $full_line | cut -d':' -f2)"
    CUTTING=$FALSE
    if [[ "${line}" == *"d_"* ]]; then
        lineout=""; cut_start=0; cut_end=0
#echo "D> line: $line"
        words=(${line})
        for ((i=0; i<${#words[@]}; i++)); do
            word=$(echo ${words[$i]})   # use echo to trim
            # start cut with word beginning "d_"
            if [[ "${word:0:2}" == "d_" ]] ; then
                cut_start=$i
                CUTTING=$TRUE
            fi
            # end cut with word after the one ending with a double-quote
            if [[ ${CUTTING} && "$(echo ${word} | rev | cut -c 1)" == '"' ]] ; then
                cut_end=$(($i+1))
                CUTTING=$FALSE
            fi
        done
#echo "D> cut_start: $cut_start   cut_end: $cut_end"
        for ((i=0; i<${#words[@]}; i++)); do
            word=$(echo ${words[$i]})   # use echo to trim whitespace
            [[ $i -lt $cut_start || $i -gt $cut_end ]] && [[ ${#word} -gt 0 ]] && \
                lineout="${lineout} ${word}"
        done
    else
        lineout="${lineout} ${line}"
    fi
    [[ ${#lineout} -gt 0 ]] && echo ${lineout}
    let n++
done
