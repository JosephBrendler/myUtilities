#!/bin/bash
source /usr/sbin/script_header_joetoo
BUILD=0.0.1

separator "get_my_cflags2.sh-$BUILD"
old_dir=$(pwd)
user_home_dir="/home/joe"

#-----[ functions ]------------------------------------------
alpha_words () { echo $(for x in $@; do echo $x; done | sort -db) ; }

#-----[ main script ]------------------------------------------
if [ "$old_dir" != "$user_home_dir" ]
then
  message "Changing from [${old_dir}] to [${user_home_dir}] and initializing..."
  cd ${user_home_dir}
else
  message "Already in [${user_home_dir}]. Initializing..."
fi

# initialize
LANG="en"
rm -v native.*; rm -v march.*
echo "" > native.cc
echo "" > march.cc

# test compiler with -march=native
message "Testing compiler with -march=native" &&
gcc -fverbose-asm -march=native native.cc -S
message "Here are the results: "
march_result=$(grep march native.s)
mcpu_result=$(grep mcpu native.s)
message "  march_result: [$march_result]"
message "  mcpu_result: [$mcpu_result]"
march=$(for word in $march_result; do echo $word; done | grep march | cut -d= -f2)
mcpu=$(for word in $mcpu_result; do echo $word; done | grep mcpu | cut -d= -f2)
message "  extracting march: [$march] and mcpu [$mcpu]"

# formulate options for test
options="-fverbose-asm"
my_options=""
[ ! -z $march ] && my_options+=" -march=${march}"
[ ! -z $mcpu ] && my_options+=" -mcpu=${mcpu}"
options+="${my_options}"

# test compiler with these options
message "Now testing with options: ${options}"
gcc -fverbose-asm ${options} march.cc -S
message "Editing output to check selected options"
alpha_words $(grep 'options' native.s | cut -d':' -f2) > native.op
alpha_words $(grep 'options' march.s | cut -d':' -f2) > march.op

# compare output from both tests and advise user accordingly
message "Comparing output ..."
separator "diff march.op native.op"
diff march.op native.op
separator "diff march.s native.s" "end"
message "If there is no output between diff separators,"
message "   then use ${my_options},"
message "   otherwise identify switches enabled by ${my_options}"
message "   that are NOT enabled by -march=native, and run the following"
message "   commands again, with those switches disabled, to determine"
message "   what else might need to be disabled or enabled."
echo
message "  $ gcc ${options} -mno-<switch1> -mno-<switch2> march.cc -S"
message '  $ alpha_words $(grep "options" march.s | cut -d":" -f2) > march.op'
message "  $ diff march.op native.op"
echo
message "See also https://wiki.gentoo.org/wiki/Safe_CFLAGS"
message "   to determine what additional switches you must/should set."
echo
message "---[ done ]---"
