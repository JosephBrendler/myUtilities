#!/bin/bash
source /usr/local/sbin/script_header_brendlefly
BUILD=0.0.1

separator "get_my_cflags2.sh-$BUILD"
old_dir=$(pwd)
user_home_dir="/home/joe"

if [ "$old_dir" != "$user_home_dir" ]
then
  message "Changing from [${old_dir}] to [${user_home_dir}] and initializing..."
  cd ${user_home_dir}
else
  message "Already in [${user_home_dir}]. Initializing..."
fi

LANG="en"
rm -v native.*; rm -v march.*
echo "" > native.cc
echo "" > march.cc
message "Testing compiler with -march=native" &&
gcc -fverbose-asm -march=native native.cc -S
message "Here is the result: "
result=$(grep march native.s)
march=$(for word in $result; do echo $word; done | grep march | cut -d= -f2)
message "  result: [$result]"
message "  extracting march: [$march]"
message "Now testing with -march=${march}"
gcc -fverbose-asm -march=${march} march.cc -S
message "Editing output files with sed to check selected options"
sed -i 1,/options\ enabled/d march.s
sed -i 1,/options\ enabled/d native.s
message "Comparing output files.  If no output, use -march=${march},"
message "   otherwise see https://wiki.gentoo.org/wiki/Safe_CFLAGS"
message "   to determine what additional switches you must set."
separator "diff march.s native.s"
diff march.s native.s
message "If not blank, then identify switches enabled by -march=${march}"
message "  that are NOT enabled by -march=native, and run the following"
message "  commands again, with those switches disabled, to determine"
message "  what else might need to be disabled or enabled:"
echo
message "  $ gcc -fverbose-asm -march=${march} -mno-<switch1> -mno-<switch2> march.cc -S"
message "  $ sed -i 1,/options\ enabled/d march.s"
message "  $ diff march.s native.s"
echo
message "---[ done ]---"
