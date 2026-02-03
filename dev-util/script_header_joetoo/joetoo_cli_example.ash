#!/bin/ash
# takes no args

#script_header_installed_dir="/usr/sbin"
script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo
# source script_header
header="${script_header_installed_dir%/}/script_header_joetoo"
if [ -f "$header" ]; then . "$header"; else echo "failed to source header; cannot continue"; exit 1; fi

#-----[ variables ]----------------------------------------------------

PN=$(basename "$0")
status_file="~/joetoo_cli_example_status"
# set default verbosity if not set externally
[ -z "$verbosity" ] && verbosity=5
echo "verbosity: $verbosity"
# initialize/clear the positional parameters
set --
# read command sequence into the positional list
while IFS= read -r _cmd; do
    [ -z "$_cmd" ] && continue
    set -- "$@" "$_cmd"
done <<EOF
printf '%s\n' "this is line 1"${US}print example line number one
printf '%s\n' "this is line 2"${US}print example line number two
printf '\n'${US}print a newline
printf '%s\n' "this is line 3 (after a blank line)"${US}print line number 3
test_function "${BGon}hello${Boff}"${US}run test_function
EOF

#-----[ functions ]----------------------------------------------------
run_sequence() # (POSIX) run command sequence; $1=status_file, $2...=commands (to be moved to header)
{ ret=0
  # guard 1 - minimum arguments check (status, start, stop, + at least 1 cmd)
  [ $# -lt 4 ] && { E_message "usage: run_sequence <status_file> <start> <stop> [commands...]"; return 1; }
  _rs_num_cmds=$(( $# - 3 ))     # count from 1
  _rs_status_file="$1"           # assign the status file
  _rs_start="${2:-1}"            # guard 2 - start step (default to zero but ensure it is an integer in range)
  ! isint "$_rs_start" && { E_message "run_sequence: start_step '$2' must be an integer 1 - ${_rs_num_cmds}"; return 1; }
  if [ "$_rs_start" -lt 1 ] || [ "$_rs_start" -gt "$_rs_num_cmds" ]; then
     E_message "run_sequence: start_step '$2' must be an integer 1 - ${_rs_num_cmds}"; return 1; fi
  _rs_stop="${3:-$_rs_num_cmds}" # guard 3 - stop step (default to num cmds but ensure it is an integer in range)
  ! isint "$_rs_stop" && { E_message "run_sequence: stop_step '$3' must be '' or an integer 1 - ${_rs_num_cmds}"; return 1; }
  if [ "$_rs_stop" -lt 1 ] || [ "$_rs_stop" -gt "$_rs_num_cmds" ]; then
    E_message "run_sequence: stop_step '$3' must be '' or an integer 1 - ${_rs_num_cmds}"; return 1; fi
  shift 3                        # shift out status, start, stop - the rest is commands
  # assign a default logFile in case one was not set externally
  [ -z "$logFile" ] && logFile="~/${PN}-$(timestamp).log"
  _rs_step=1
  # Now $@ contains ONLY the commands because we shifted the status file out
  while [ "$_rs_step" -le "$_rs_stop" ]; do               # enforces upper bound
    if [ "$_rs_step" -lt "$_rs_start" ]; then
      shift; _rs_step=$(( _rs_step + 1 )); continue; fi   # enforces lower bound (shift into range)
    # assign commadn and description from input, delimitted by unit separator ($US)
    _rs_entry="$1"  # contains
    _rs_cmd="${_rs_entry%%${US}*}"  # the actual command
    _rs_desc="${_rs_entry#*${US}}"  # human readable description
    _rs_clean_entry=$(printf -- '%b' "$_rs_entry" | strip_ansi | _translate_escapes)
    _rs_clean_cmd=$(printf -- '%b' "$_rs_cmd" | strip_ansi | _translate_escapes)

    d_message "_rs_start: $_rs_start" 5
    d_message "_rs_stop: $_rs_stop" 5
    d_message "_rs_step: $_rs_step" 5
    d_message "_rs_clean_entry: $_rs_clean_entry" 5
    d_message "_rs_clean_cmd: $_rs_clean_cmd" 5
    d_message "_rs_desc: $_rs_desc" 5
    d_message "termwidth: $(termwidth)" 5

    # if INTERACTIVE, confirm before executing the step
    if [ "$INTERACTIVE" ]; then
      _rs_msg="${BYon}Are you ready to (${_data_color}${_rs_step}${BYon}"
      _rs_msg="${_rs_msg} ${_op_color}${_rs_desc}${BYon}? ${Boff}"
      yns_prompt "$_rs_msg"
      _rs_response="$response"
    else
      _rs_response="yes"
    fi  # INTERACTIVE?
    # execute according to response
    case "$_rs_response" in
      [Yy]* )
        # start with a separator for every step
        d_log_separator "$PN" "(step [$_rs_step]: $_rs_desc)" 1
        d_log_message "${LBon}Executing: ${BYon}${_rs_cmd}${Boff}" 1
        d_log_message "executing step [$_rs_step]: $_rs_clean_cmd" 2
        # eval expands variables inside the string
        eval "$_rs_cmd"; _rs_result=$?
        ### don't die - let the calling script decide what to do based on return
        ### d_log_handle_result $_rs_result 1 || die "failed to execute step [$_rs_step]: $_rs_clean_cmd"
        # display/log result and set bit in ret status binary bitmask
        d_log_handle_result $_rs_result '' "failed with exit code [$_rs_result]" 1 || \
            ret=$(( ret | 1 << _rs_step )) ;;
      [Ss]* )
        _rs_msg="${BYon}Skipping step [${_data_color}${_rs_step}${BYon}]:"
        _rs_msg="${_rs_msg} ${_op_color}${_rs_desc}${BYon} as instructed${Boff}"
        d_log_message "$_rs_msg" 1 ;;
      * )
        d_log_message "${BRon}Aborting sequence, as instructed${Boff}" 1
        ret=1; break ;;
    esac
    _rs_step=$(( _rs_step + 1 ))
    shift  # drop current and go to next command if any remain
  done
  unset -v _rs_status_file _rs_step _rs_cmd _rs_result _rs_entry _rs_desc
  unset -v _rs_response _rs_clean_cmd _rs_num_cmds _rs_start _rs_stop _rs_msg
  return $ret
}
# usage: run_sequence <status_file> <start> <stop> [commands...]
# args: $1 (string) path to sequence status file
# args: $2 (int) starting step (1-indexed)
# args: $3 (int) stopping step (1-indexed)
# args: $4... (string) command and description delimited by ${US}
# vars: INTERACTIVE, logFile, PN, US, _data_color, _op_color
# ret: 0 on success, 1 on abort, or bitmask of failed steps
# deps: isint, yns_prompt, d_log_separator, d_log_message, d_log_handle_result, strip_ansi, _translate_escapes

test_function() {
  ret=0; _tf_in="$1"
  printf '%b\n' "this was printed by the test function: $_tf_in" || ret=1
  unset -v _tf_in
  return $ret
}
# @usage run_sequence <status_file> <start> <stop> [commands...]
#-----[ main script ]----------------------------------------------------

separator "$PN" "(starting)"

run_sequence "$status_file" '' '' "$@"

