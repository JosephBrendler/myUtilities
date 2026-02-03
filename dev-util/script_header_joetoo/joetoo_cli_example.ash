#!/bin/ash
# takes no args

#script_header_installed_dir="/usr/sbin"
script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo
# source script_header
header="${script_header_installed_dir%/}/script_header_joetoo"
if [ -f "$header" ]; then . "$header"; else echo "failed to source header; cannot continue"; exit 1; fi

#-----[ variables ]----------------------------------------------------

varlist="PN BUILD status_file verbosity bool.INTERACTIVE bool.RESUME BREAK num_cmds starting_step stopping_step"

#-----[ functions ]----------------------------------------------------

initialize_variables() {
  _iv_FLAGGED=$FALSE

  initialize_vars  # sets all to null/$FALSE/No

  message_n "initializing PN"
  PN=$(basename "$0")
  handle_result $? "$PN" '' || _iv_FLAGGED=$TRUE

  message_n "initializing BUILD"
  BUILD="0.0.0-r7"
  handle_result $? "$BUILD" '' || _iv_FLAGGED=$TRUE

  message_n "initializing customization_root"
  customization_root="/home/joe/myUtilities/dev-util/script_header_joetoo"
  handle_result $? "$customization_root" '' || _iv_FLAGGED=$TRUE

  message_n "initializing status_file"
  status_file="~/joetoo_cli_example_status"
  handle_result $? "$status_file" '' || _iv_FLAGGED=$TRUE

  message_n "maybe initializing verbosity"
  # set default verbosity if not set externally
  if [ -z "$verbosity" ] ; then
    verbosity=3
    handle_result $? "now set: $verbosity" '' || _iv_FLAGGED=$TRUE
  else
    handle_result $TRUE "already set: $verbosity" ''
  fi

  message_n "initializing INTERACTIVE"
  INTERACTIVE=$TRUE
  handle_result $? "$INTERACTIVE" '' || _iv_FLAGGED=$TRUE

  message_n "initializing RESUME"
  RESUME=$FALSE
  handle_result $? "$RESUME" '' || _iv_FLAGGED=$TRUE

  message_n "creating tempfile for command sequnce"
  cmd_seq_file=$(mktemp /tmp/${PN}.XXXXXX)
  handle_result $? "$cmd_seq_file" '' || _iv_FLAGGED=$TRUE

  message_n "setting trap to remove tempfile on EXIT"
  trap 'rm -f "$cmd_seq_file"' EXIT

  message_n "initializing command sequence"
  num_cmds=0
# heredoc needs to be on the left edge; no leading whitespace
# initialize/clear the positional parameters
set --
# read command sequence into the positional list
while IFS= read -r _cmd; do
      [ -z "$_cmd" ] && continue
      # write directly to the file instead of using  ' set -- "$@" '
      printf '%s\n' "$_cmd" >> "$cmd_seq_file"
      num_cmds=$(( num_cmds + 1 ))
done <<EOF
printf '%s\n' "this is line 1"${US}print example line number one
printf '%s\n' "this is line 2"${US}print example line number two
printf '\n'${US}print a newline
printf '%s\n' "this is line 3 (after a blank line)"${US}print line number 3
test_function "${BGon}hello${Boff}"${US}run test_function
EOF
  handle_result $? "num_cmds: $num_cmds" '' || _iv_FLAGGED=$TRUE

  message_n "initailizing starting_step"
  starting_step=1
  handle_result $? "$starting_step" '' || _iv_FLAGGED=$TRUE

  message_n "initializing stopping step"
  stopping_step="$num_cmds"
  handle_result $? "$stopping_step" '' || _iv_FLAGGED=$TRUE

  [ "$FLAGGED" ] && return 1
  return 0
}

usage()                # explain default usage; mod with local "usage module"
{
  N=$(( ${num_cmds} -1 ))
  separator "${PN}-${BUILD}" "(usage)"
  E_message "${BRon}Usage: ${BGon}${PN} [-[options]] ${Boff}"
  message "${BYon}valid commandline options --${Boff}"
  message "  -i | --interactive......: run supervised; confirm execution of each step"
  message "  -n | --noninteractive...: run un-supervised; automatically do each step"
  message "  -s | --status....: return status (next step, step_number)"
  message "  -r | --resume....: resume at next step in status_file"
  message "  -v | --verbose...: increase verbosity"
  message "  -q | --quiet.....: decrease verbosity"
  message "  -[0-${N}]..........: save N to status file and resume at step N"
  message "  ${BYon}*${Boff} Single-character options may be combined."
  message "    e.g. ${BGon}${PN} --verbose -nqr8${Boff} would resume non-interactively"
  message "    (automatic, unsupervised) at step 8 with normal verbosity"
  message "${BMon}Caveat:${Boff}"
  message "   -i (interactive/supervised) is on by default"
  message "   -r (resume) sets starting_step to # in [ $status_file ]"
  message "   -[0-${N}] sets starting_step (default 0 otherwise)"
  # source user-script specific usage-module which should be built in the same format
  message "${BMon}additional ${customization_root} - commandline options:${Boff}"
  [ -f ${customization_root%/}/local.usage ] && source ${customization_root%/}/local.usage
  printf '\n'
  message "${BYon}${PN} workflow sequence (steps):${Boff}"
  for _u_step in $(seq 1 $num_cmds); do
    _u_entry=$(sed -n "${_u_step}p" "$cmd_seq_file") # extract the specific line corresponding to the current step counter
    _u_desc="${_u_entry#*${US}}"                     # human readable description
    printf '    %b[%b%02d%b]%b: ' "${BBon}" "${Mon}" "$_u_step" "${BBon}" "${Boff}"
    printf '%b%s%b\n' "${Con}" "${_u_desc}" "${Boff}"
  done

  unset -v _u_step _u_entry _u_desc
  die "dying; process [$$]"
}

validate_status_file()  # validate or create command sequence status file $1
{
    [ $# -ne 1 ] && E_message "Error: must specify status_file" && return 1
    status_file=$1
    d_log_message "status_file: [ ${status_file} ]" 3
    status_dir=$(dirname ${status_file})
    d_log_message "status_dir: [ ${status_dir} ]" 3
    message_n "validating status_dir [${status_dir}] ..."
    if [ ! -d ${status_dir} ] ; then
        printf '%b%s%b' "${BYon}" " (creating) ... " "${Boff}"
        mkdir -p ${status_dir}
        handle_result $? "created" '' || { E_message "failed to create status_dir"; return 1; }
    else
        printf '%b%s%b' "${BGon}" " (valid) ... " "${Boff}"
        right_status $TRUE
    fi
    message_n "validating status_file [${status_file}] ..."
    if [ ! -f ${status_file} ] ; then
        printf '%b%s%b' "${BYon}" " (creating) ... " "${Boff}"
        echo "1" > ${status_file}  # 1-indexed command sequence
        handle_result $? "created" '' || { E_message "failed to create status_file"; return 1; }
    else
        printf '%b%s%b' "${BGon}" " (valid) ... " "${Boff}"
        right_status $TRUE
    fi
    # final validation
    message_n "re-verifying status_file [${status_file}] ..."
    [ -f ${status_file} ] ; result=$?
    right_status $result
    return $result
}

process_cmdline() {
  # local helper (defined only inside this scope) to get status
  separator "$PN" "(process_cmdline)"
  _pc_emit_status() {
      if [ -f "$status_file" ]; then
          read _pc_val < "$status_file"
          message "${BWon}Status: Step $(( _pc_val - 1 )) complete; next is [ ${BMon}${_pc_val:-1}${BWon} ]${Boff}"
      else
          message "${BWon}Status: No status file; sequence not yet started${Boff}"
      fi
      exit 0
  }

    # baseline optstring (standard flags only) (see getopts --help)
    _pc_optstring="insrvq"
    d_log_message "_pc_optstring: $_pc_optstring" 5
    d_log_message "\$@: $@" 5
    while [ $# -gt 0 ]; do
        d_log_message "\$1: $1" 5
        case "$1" in

            # tier 1 - standard long options
            --status)  # POSIX math: report step-1 as completed
                if [ -f "$status_file" ]; then read _pc_val < "$status_file"
                    message "${BWon}Status: Step $(( _pc_val - 1 )) complete; next is [ ${BMon}${_pc_val}${BWon} ]${Boff}"
                else message "${BWon}Status: No status file; sequence not yet started${Boff}"; fi; exit 0 ;;
            --resume) RESUME=$TRUE; if isint "$2"; then starting_step="$2"; shift 2
                else  read starting_step < "$status_file" 2>/dev/null || starting_step=1; shift; fi
                d_log_message "set RESUME = $(status_color $RESUME)$(TrueFalse RESUME); starting_step: [starting_step]" 3 ;;
            --interactive)    INTERACTIVE=$TRUE; shift
                d_log_message "set INTERACTIVE = $(status_color $INTERACTIVE)$(TrueFalse $INTERACTIVE)" 3 ;;
            --noninteractive) INTERACTIVE=$FALSE; shift
                d_log_message "set INTERACTIVE = $(status_color $INTERACTIVE)$(TrueFalse $INTERACTIVE)" 3 ;;
            --verbose)        verbosity=$(( verbosity + 1 )); shift
                d_log_message "set verbosity: [$verbosity]" 3 ;;
            --quiet)          verbosity=$(( verbosity - 1 )); shift
                d_log_message "set verbosity: [$verbosity]" 3 ;;

            # tier 2 - clustered shorts & embedded numbers (e.g. -iv12)
            -*) # remove '-', and "peel" digits from the cluster (e.g., "iv24" -> "24")
                # ( tr: -d deletes; -c '0-9' specifies the complement of numbers )
                _pc_cluster=${1#-}; _pc_num=$(echo "$_pc_cluster" | tr -d -c '0-9')
                if [ -n "$_pc_num" ]; then starting_step="$_pc_num"; RESUME=$TRUE; fi
                # use getopts to process the letters in the cluster (see getopts --help)
                # each iteration of "getopts $_pc_optstring _pc_opt" assigns the next
                # letter in whatever positional parameter OPTIND is pointing at
                # when it runs out of letters, it increments OPTIND
                # (but this loop shifts and resets OPTIND to 1)
                while getopts "$_pc_optstring" _pc_opt; do
                    d_log_message "_pc_opt: $_pc_opt" 5
                    case "$_pc_opt" in
                        i) INTERACTIVE=$TRUE
                            d_log_message "set INTERACTIVE = $(status_color $INTERACTIVE)$(TrueFalse $INTERACTIVE)" 3 ;;
                        n) INTERACTIVE=$FALSE
                            d_log_message "set INTERACTIVE = $(status_color $INTERACTIVE)$(TrueFalse $INTERACTIVE)" 3 ;;
                        v) [ "$verbosity" -lt 6 ] && verbosity=$(( verbosity + 1 ))
                            d_log_message "set verbosity: [$verbosity]" 3 ;;
                        q) [ "$verbosity" -gt 0 ] && verbosity=$(( verbosity - 1 ))
                            d_log_message "set verbosity: [$verbosity]" 3 ;;
                        r) RESUME=$TRUE
                            # read file only if no number was found in this cluster
                            if [ -z "$_pc_num" ]; then read starting_step < "$status_file" 2>/dev/null || starting_step=1; fi
                            d_log_message "set RESUME = $(status_color $RESUME)$(TrueFalse RESUME); starting_step: [starting_step]" 3 ;;
                        s) # re-use the status logic above (manually)
                           read _pc_val < "$status_file" 2>/dev/null || _pc_val=1
                           message "Next step: $_pc_val"; exit 0 ;;
                        *) # check local hook extension if it exists
                            if [ "$(command -v local_process_argument)" ]; then
                                local_process_argument "$_pc_opt" "$OPTARG"
                                _rs_result=$?
                            else E_message "Invalid cmdline argument [$1]"; usage; fi;
                            # got here w/o getting shunted to usage - check return ffom local extension
                            # (code 0: success; 6: used an operand (need extra shift); other: fail
                            [ "$_rs_result" -eq 6] && shift
                            ret="$_rs_result"
                            ;;
                    esac
                done  # current positional parameter's letters have all been checked
                shift $(( OPTIND - 1 )) # shift to next word/arg
                OPTIND=1 ;;             # point at first word/arg again

            # tier 3 - positional numbers (e.g. just '12') ---
            [0-9]*) # if it is not a pure number (like 24j); treat as operand or error
                if isint "$1"; then starting_step="$1"; RESUME=$TRUE; shift
                else E_message "Invalid operand: $1"; usage; fi ;;
            *) shift ;;  # ignore all else
        esac
    done  # done with $1 - each case above shifted at least 1, so drive on

    unset -v _pc_optstring _pc_cluster _pc_num _pc_val _pc_opt _pc_total_steps
    unset -f _pc_emit_status
    return $ret
}
# usage: process_cmdline [args]
# args: $@: command line arguments to be parsed
# vars: INTERACTIVE, RESUME, starting_step, verbosity, status_file
# ret: 0: success; exit 1: invalid operand or out of range
# deps: isint, message, E_message, usage, tr, echo, read, cat
# rule: variables used only locally are prefixed with _pc_ and unset at bottom;
# rule: starting_step is validated against the number of positional parameters;
# rule: last-instruction-wins precedence is enforced via linear while-loop;
# ex: process_cmdline -iv24; process_cmdline --resume 5; process_cmdline -s

run_sequence() # (POSIX) run command sequence; $1=status_file, $2=start, $3=stop
{ ret=0
  # guard 1 - minimum arguments check (status, start, stop, + at least 1 cmd)
  [ $# -lt 3 ] && { E_message "usage: run_sequence <status_file> <start> <stop>"; return 1; }
  _rs_status_file="$1"           # assign the status file
  _rs_start="${2:-1}"            # guard 2 - start step (default to zero but ensure it is an integer in range)
  ! isint "$_rs_start" && { E_message "run_sequence: start_step '$2' must be an integer 1 - ${num_cmds}"; return 1; }
  if [ "$_rs_start" -lt 1 ] || [ "$_rs_start" -gt "$num_cmds" ]; then
     E_message "run_sequence: start_step '$2' must be an integer 1 - ${num_cmds}"; return 1; fi
  _rs_stop="${3:-$num_cmds}" # guard 3 - stop step (default to num cmds but ensure it is an integer in range)
  ! isint "$_rs_stop" && { E_message "run_sequence: stop_step '$3' must be '' or an integer 1 - ${num_cmds}"; return 1; }
  if [ "$_rs_stop" -lt 1 ] || [ "$_rs_stop" -gt "$num_cmds" ]; then
    E_message "run_sequence: stop_step '$3' must be '' or an integer 1 - ${num_cmds}"; return 1; fi
  # assign a default logFile in case one was not set externally
  [ -z "$logFile" ] && logFile="~/${PN}-$(timestamp).log"
  _rs_step=1
  while [ "$_rs_step" -le "$_rs_stop" ]; do        # enforces upper bound
    if [ "$_rs_step" -lt "$_rs_start" ]; then
      _rs_step=$(( _rs_step + 1 )); continue; fi   # enforces lower bound (shift into range)
    # assign commadn and description from input, delimitted by unit separator ($US)
    _rs_entry=$(sed -n "${_rs_step}p" "$cmd_seq_file") # extract the specific line corresponding to the current step counter
    _rs_cmd="${_rs_entry%%${US}*}"  # the actual command
    _rs_desc="${_rs_entry#*${US}}"  # human readable description
    _rs_clean_entry=$(printf -- '%b' "$_rs_entry" | strip_ansi | _translate_escapes)
    _rs_clean_cmd=$(printf -- '%b' "$_rs_cmd" | strip_ansi | _translate_escapes)

    d_log_message "_rs_start: $_rs_start" 5
    d_log_message "_rs_stop: $_rs_stop" 5
    d_log_message "_rs_step: $_rs_step" 5
    d_log_message "_rs_clean_entry: $_rs_clean_entry" 5
    d_log_message "_rs_clean_cmd: $_rs_clean_cmd" 5
    d_log_message "_rs_desc: $_rs_desc" 5
    d_log_message "termwidth: $(termwidth)" 5

    # if INTERACTIVE, confirm before executing the step
    if [ "$INTERACTIVE" ]; then
      _rs_msg="${BYon}Are you ready to (${_data_color}${_rs_step}${BYon})"
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
  done
  unset -v _rs_status_file _rs_step _rs_cmd _rs_result _rs_entry _rs_desc
  unset -v _rs_response _rs_clean_cmd _rs_start _rs_stop _rs_msg
  return $ret
}
# @usage: run_sequence <status_file> <start> <stop>
# @args: $1 (string) path to sequence status file
# @args: $2 (int) starting step (1-indexed)
# @rule: $2 start must be '' or integer 1(default) - num_cmds
# @args: $3 (int) stopping step (1-indexed)
# @rule: $3 stop must be '' or integer 1 - num_cmds(default)
# @vars: INTERACTIVE, logFile, PN, US, _data_color, _op_color
# @ret: 0 on success, 1 on abort, or bitmask of failed steps
# @deps: isint, yns_prompt, d_log_separator, d_log_message, d_log_handle_result, strip_ansi, _translate_escapes

test_function() {
  ret=0; _tf_in="$1"
  printf '%b\n' "this was printed by the test function: $_tf_in" || ret=1
  unset -v _tf_in
  return $ret
}
# @usage test_function <message>
#-----[ main script ]----------------------------------------------------

separator "$PN" "(starting)"

initialize_variables || die "failed to initialize_variables"

validate_status_file "$status_file" || die "failed to validate_status_file"

show_config

process_cmdline "$@" || die "failed to process_cmdline"

show_config

run_sequence "$status_file" '' ''
ret=$?
message_n "run_sequence completed with "
handle_result $ret '' ''
exit $ret
