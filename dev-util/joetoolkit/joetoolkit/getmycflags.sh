#!/bin/bash
# getmycflags.sh
# Author: Joe brendler 23 January 2017
# Implements the procedure specified at https://wiki.gentoo.org/wiki/Safe_CFLAGS
#   to determine safe CFLAGS to set for this (arbitrary) machine

#---[ local definitions ]--------------------------------------------------------
BUILD=0.0.1

old_dir=$(pwd)
user_home_dir="$HOME"

PN=${0##*/}

#---[ function blocks ]----------------------------------------------------------

#---[ main script ]--------------------------------------------------------------
separator "$PN-$BUILD"

checknotroot

if [ "$old_dir" != "$user_home_dir" ]
then
  message "Changing from [${old_dir}] to [${user_home_dir}] and initializing..."
  cd ${user_home_dir}
else
  message "Already in [${user_home_dir}]. Initializing..."
fi

LANG="en"
rm -v native.* 2>/dev/null; rm -v march.* 2>/dev/null
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
message "Comparing output files..."
message "  ${BYon}If no output between separators below, then use -march=${march}${Boff} ,"
message "   otherwise use the procedure at https://wiki.gentoo.org/wiki/Safe_CFLAGS"
message "   to determine what additional switches you must set. (see further below)"
separator "diff march.s native.s"
diff march.s native.s
separator "diff march.s native.s"
message "${Byon}If not blank between separators above, then${Boff}"
message "  (1) Identify <switch1> switches that were enabled by -march=${march},"
message "      but were NOT enabled by -march=native, and"
message "  (2) Identify <switch2> switches that were enabled by -march=native,"
message "      but were NOT enabled by -march=${march}, and"
message "  (3) Run the following commands, with those switches disabled/enabled (respectively)"
message "      to determine what else might need to be disabled or enabled:"
echo
message "  $ gcc -fverbose-asm -march=${march} -mno-<switch1> -m<switch2> march.cc -S"
message "  $ sed -i 1,/options\ enabled/d march.s"
message "  $ diff march.s native.s"
echo
message "I will now try to do that automatically..."
march_s_has=$(diff march.s native.s | grep '< #' | sed -e 's/#//' -e 's/<//')
native_s_has=$(diff march.s native.s | grep '> #' | sed -e 's/#//' -e 's/>//')
message "  Using march.s switches: $march_s_has"
message "  Using native.s switches: $native_s_has"
# go through each in march.s and see if there's a match in native.s
march_s_has_out=$march_s_has
native_s_has_out=$native_s_has
for m_swx in $march_s_has
do
  debug_msg "  Checking native_s_has for a match to [$m_swx]"
  for n_swx in $native_s_has
  do
    if [[ "$n_swx" == "$m_swx" ]]
    then
      debug_msg "    (found in both, dropping)"
      march_s_has_out="$(echo $march_s_has_out | sed "s/$m_swx//")"
      native_s_has_out="$(echo $native_s_has_out | sed "s/$n_swx//")"
    fi
  done
done
# convert what is left in $march_s_has_out into "no-" switches
march_s_has_out_final=""
for m_swx in $march_s_has_out
do
  march_s_has_out_final="$march_s_has_out_final $(echo $m_swx | sed 's/-m/-mno-/')"
done
message "${BYon}Here are your suggested CFLAGS:${Boff}"
message "${BGon}  -march=${march}${march_s_has_out_final} ${native_s_has_out}${Boff}"

if [ "$old_dir" != "$user_home_dir" ]
then
  message "Cleaning up and changing back from [${user_home_dir}] to [${old_dir}]..."
  rm march.*; rm native.*
  cd ${old_dir}
else
  message "Cleaning up..."
  rm -v native.* 2>/dev/null; rm -v march.* 2>/dev/null
fi
message "---[ done ]---"
