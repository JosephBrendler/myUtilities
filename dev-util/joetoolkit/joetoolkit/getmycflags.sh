#!/bin/bash
source /usr/sbin/script_header_joetoo
PN=${0##*/}

#BUILD=0.0.1
if [ -f /etc/joetoolkit/BUILD ]; then . /etc/joetoolkit/BUILD; else BUILD=0.0.2; fi

separator "${PN}-${BUILD}"
old_dir=$(pwd)
user_home_dir="$HOME"

#-----[ functions ]------------------------------------------
alpha_words () { echo $(for x in $@; do echo $x; done | sort -db) ; }

#-----[ main script ]------------------------------------------
if [ "$old_dir" != "$user_home_dir" ]
then
  j_msg -${notice} -p "Changing from [${old_dir}] to [${user_home_dir}] and initializing..."
  cd ${user_home_dir}
else
  j_msg -${notice} -p "Already in [${user_home_dir}]. Initializing..."
fi

# initialize
LANG="en"
rm -v native.*; rm -v march.*
echo "" > native.cc
echo "" > march.cc

# test compiler with -march=native
j_msg -${notice} -p "Testing compiler with -march=native" &&
gcc -fverbose-asm -march=native native.cc -S
j_msg -${notice} -p "Here are the results: "
march_result=$(grep march native.s)
mcpu_result=$(grep mcpu native.s)
j_msg -${notice} -m "  march_result: [$march_result]"
j_msg -${notice} -m "  mcpu_result: [$mcpu_result]"
march=$(for word in $march_result; do echo $word; done | grep march | cut -d= -f2)
mcpu=$(for word in $mcpu_result; do echo $word; done | grep mcpu | cut -d= -f2)
j_msg -${notice} -p "  extracting march: [$march] and mcpu [$mcpu]"

# formulate options for test
options="-fverbose-asm"
my_options=""
[ ! -z $march ] && my_options+=" -march=${march}"
[ ! -z $mcpu ] && my_options+=" -mcpu=${mcpu}"
options+="${my_options}"

# test compiler with these options
j_msg -${notice} -p "Now testing with options: ${options}"
gcc -fverbose-asm ${options} march.cc -S
j_msg -${notice} -p "Editing output to check selected options"
alpha_words $(grep 'options' native.s | cut -d':' -f2) > native.op
alpha_words $(grep 'options' march.s | cut -d':' -f2) > march.op

# compare output from both tests and advise user accordingly
j_msg -${notice} -p "Comparing output ..."
separator "diff march.op native.op"
diff march.op native.op
separator "diff march.s native.s" "end"
j_msg -${notice} -p "If there is no output between diff separators,"
j_msg -${notice} -m "   then use ${my_options},"
j_msg -${notice} -m "   otherwise identify switches enabled by ${my_options}"
j_msg -${notice} -m "   that are NOT enabled by -march=native, and run the following"
j_msg -${notice} -m "   commands again, with those switches disabled, to determine"
j_msg -${notice} -m "   what else might need to be disabled or enabled."
echo
j_msg -${notice} -m "  $ gcc ${options} -mno-<switch1> -mno-<switch2> march.cc -S"
j_msg -${notice} -m '  $ alpha_words $(grep "options" march.s | cut -d":" -f2) > march.op'
j_msg -${notice} -m "  $ diff march.op native.op"
echo
j_msg -${notice} -p "See also https://wiki.gentoo.org/wiki/Safe_CFLAGS"
j_msg -${notice} -m "   to determine what additional switches you must/should set."
echo
j_msg -${notice} -p "---[ done ]---"
