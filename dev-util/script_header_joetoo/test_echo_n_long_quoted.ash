#!/bin/sh
# verbosity=${_verbosity} echo_n_long v0.2.0 test battery

script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo

echo -n "sourcing test header"
source "${script_header_installed_dir}/script_header_joetoo_posix"
right_status $?

#-----[ variables ]------------------------------------------------------------------------------------

_test_case=$1
_verbosity=${2:-1}
FULLNAME="$0"
PN=$(basename "$0")

# setup environment
#export COLUMNS=40
#_tw=40
_indent=10

#-----[ functions ]------------------------------------------------------------------------------------

usage() {
  E_message "usage: ${PN} [test_case]"
  printf "\n"
  message "${BYon}Current test inventory --${Boff}"
  grep -E '${W1}[0-9]${W1})' "${FULLNAME}"
}

do_test() {
  _tc=$1
  case "$_tc" in
    1 ) # test 1: far-right start (greedy wrap)
      separator "greedy wrap test"
      message "parameters 35 $_indent"
      printf "\r"; CUF 35
      # function should see it is at 35, realize "greedy" won't fit, and wrap to 10
      verbosity=${_verbosity} echo_n_long 35 $_indent "This sentence should jump to a new line and indent to ten immediately."
      printf "\n"
      ;;
    2 ) # test 2: fragment finish (short string)
      separator "fragment finish test"
      message "parameters 5 $_indent"
      printf "\r"; CUF 5
      # function should see it is at 5, realize the whole thing fits, and print on one line
      verbosity=${_verbosity} echo_n_long 5 $_indent "Small fragment."
      printf "\n"
      ;;
    3 ) # test 3: impossible word (emergency fallback)
      separator "impossible word test"
      message "parameters 0 $_indent"
      # tests the "case 4" emergency print to prevent infinite loops
      # the word is 50 chars, terminal is 40.
      _long_word="ThisIsAWordThatIsWayLongerThanTheTerminalWidthLimit"
      verbosity=${_verbosity} echo_n_long 0 $_indent $_long_word "and then some normal text."
      printf "\n"
      ;;
    4 ) # test 4: indent vs current col sync
      separator "indent sync test"
      message "parameters 20 5"
      printf "\r"; CUF 20
      # current=20, indent=5. first line stays at 20, wrap goes to 5.
      verbosity=${_verbosity} echo_n_long 20 5 "This starts at twenty but wraps back to five to show the hanging indent works."
      printf "\n"
      ;;
    5 ) # test 5: ansi safety check
      separator "ansi safety test"
      message "parameters 20 5"
      verbosity=${_verbosity} echo_n_long 0 5 "Normal text ${BGon}Green_Word_That_Is_Long_And_Colored${Boff} Normal text again."
      printf "\n"
        unset -v _tc
      ;;
    * )  E_message "invalid test_case [$_test_case]"; useage;;
  esac
  return 0
}

#-----[ main script ]------------------------------------------------------------------------------------
checkroot
separator "$PN" "(starting)"
message "${LBon}input test_case${Boff}: [${Mon}${_test_case}${Boff}]"
message "dimensions: $(termwidth)x$(termheight)"
message "verbosity: $_verbosity"

if isnumber "${_test_case}"; then
  do_test "${_test_case}"
else
  E_message "input test_case either null or invalid, running full sequence (CTRL-C to cancel)"
  for x in $(seq 1 5); do
    do_test "${x}"
  done
fi
separator "$PN" "(done)"
