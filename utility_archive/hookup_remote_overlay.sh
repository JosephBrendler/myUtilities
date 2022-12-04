#!/bin/bash
# create my local "joetoo" overlay on a system that doesn't have it yet
# Joe Brendler (brendlefly62) 27 January 2017
# Updated 28 Jan 17 to eliminate dependency on eix (still dep on gentoolkit)
# Note: line 514 - want layman to be ver 2.1.0 or newer

#---[ local definitions ]---------------------------------------------
source /usr/local/sbin/script_header_brendlefly
source /usr/local/sbin/script_header_brendlefly_extended
BUILD=0.0.1a
repo_name="joetoo"
repo_location="/var/lib/layman"
layman_conf="/etc/portage/repos.conf/layman.conf"
layman_cfg="/etc/layman/layman.cfg"
repo_name="joetoo"
overlay_url="https://raw.githubusercontent.com/JosephBrendler/joetoo/master/repositories.xml"
my_priority="10"
my_location="/var/lib/layman/joetoo"
my_layman_type="git"
my_sync_type="git"
my_sync_uri="https://github.com/JosephBrendler/joetoo.git"
my_branch="master"
my_auto_sync="Yes"

# copied from script_header_brendlefly so I don't have to source it on a box
# that hasn't been able to get it because it's in the overlay we're trying to hook up
ROOT_UID=0	 # Only users with $UID 0 have root privileges
#  Error message used by various scripts
E_NOTROOT="Must be root to run this script."
E_ROOT="Please run this script as user, not root."
E_BAD_ARGS="Improperly formatted command line argument."

TRUE=0    # will evaluate to be logically true in a boolean operation
FALSE=""  # will evaluate to be logically false in a boolean operation
  # play with test function:
  # test() { [ $1 ] && echo "$1 is true" || echo "$1 is false"; }
VERBOSE=$FALSE
DIFF=$TRUE
INSTALL=$TRUE

#--[ Easy ANSI Escape sequences to put color in my scripts ]---
#  see http://en.wikipedia.org/wiki/ANSI_escape_code
#  see also http://ascii-table.com/ansi-escape-sequences.php

CSI="\033["             # control sequence initiator == hex "\x1b["
#---[ Select Graphics Rendition on/off ]---------------------------
BOLD="1"       # bold on
UL="4"         # underline on
BLINK="5"      # slow blink on
BLINKFAST="6"  # fast blink on
ULoff="24"     # underline off
BLINKoff="25"  # blink off
SGRoff="0"     # Bold off (reset all SGR (e.g. blink, underline)
#---[ Set Text Color, Foreground ]---------------------------------
BLACK="30"     # foreground black
RED="31"       # foreground red
GREEN="32"     # foreground green
YELLOW="33"    # foreground yellow
BLUE="34"      # foreground blue
MAG="35"       # foreground magenta (it's like fucia)
LBLUE="36"     # foreground light blue (cyan)
WHITE="37"     # foreground white (cyan)
#---[ Set Background Color ]---------------------------------------
BACKoff="40"   # background black
RBACK="41"     # background red
GBACK="42"     # background green
YBACK="43"     # background yellow
BBACK="41"     # background blue
MBACK="41"     # background magenta
LBACK="41"     # background light blue (cyan)
WBACK="41"     # background white
#---[ My Favorite Colors (terminate with ${Boff} ]-----------------
BRon="${CSI}${RED};${BOLD}m"
BGon="${CSI}${GREEN};${BOLD}m"
BYon="${CSI}${YELLOW};${BOLD}m"
BBon="${CSI}${BLUE};${BOLD}m"
BMon="${CSI}${MAG};${BOLD}m"
LBon="${CSI}${LBLUE};${BOLD}m"
BWon="${CSI}${WHITE};${BOLD}m"
Boff="${CSI}${SGRoff}m"          # Bold off (reset all SGR (e.g. blink, underline)


#---[ local functions ]-----------------------------------------------

useage() {  E_message "useage: check_write_laymancfg [-d|--show-diff] [-I|--install] [-v|--verbose]"; }

process_arguments() {
  d_message "${BMon}Inside process_arguments with [$@]${boff}"
  # process arguments and set associated flags
  [[ $# -gt 3 ]] && useage
  ERR=$FALSE
  while [[ $# -gt 0 ]]
  do
    d_message "p.a. Arg=[$1]"
    case $1 in
      "-d" | "--show-diff" ) DIFF=$TRUE;;
      "-I" | "--install"   ) INSTALL=$TRUE;;
      "-v" | "--verbose"   ) VERBOSE=$TRUE;;
       *                   ) ERR=$TRUE; useage;;
    esac
    shift
  done
  [[ $ERR ]] && return 1 || return 0
}

keyword_and_emerge_layman()
{
  chost=$(grep CHOST= /etc/portage/make.conf | cut -d'=' -f2 | sed 's/"//g' | cut -d'-' -f1)
  case $chost in
    x86_64) arch="amd64";;
    i686  ) arch="x86";;
    arm*  ) arch="arm";;
    *     ) E_message "Error: could not set arch in order to keyword layman"; exit 1;;
  esac
  ## TODO: skip keywording if there is an available stable version > 2.1.0
  # look for existing keyword
  key_word=$(grep -iR layman /etc/portage/ | cut -d: -f2)
  message "Looking for pre-established keyword, found: [${key_word}]"
  message "Checking if [${key_word}] != [app-portage/layman ~${arch}]"
  if [[ "${key_word}" != "app-portage/layman ~${arch}" ]]
  then
    # keyword layman to get the newer (repos.conf) version
    if [[ -d /etc/portage/package.keywords ]] # if directory exists, just create file in it
    then
      keyword_file="/etc/portage/package.keywords/layman"
    else  #keword directory does not exist, so append to or create /etc/portage/package.keywords (file)
      keyword_file="/etc/portage/package.keywords"
    fi
    # append the keyword (creating file if doesn't already exist)
    echo -e "app-portage/layman ~${arch}\ndev-python/ssl-fetch ~${arch}\n" >> $keyword_file && \
      message "${BYon}Successfully wrote:${Boff} \napp-portage/layman ~${arch}\ndev-python/ssl-fetch ~${arch}\n${BYon}to $keyword_file${Boff}"
  else
    message "Layman is already keyworded for ${arch}, continuing..."
  fi
  # now emerge the right version of layman
  emerge -av app-portage/layman
}

# functions below copied from script_header_brendlefly and its extension
#   script_header_brendlefly_extended -- so I don't try to source
#   those headers on a box that doesn't have them installed, because
#   the headers are in the overlay we're trying to hook up
checknotroot()     # Run as root, of course.
{
  if [ "$UID" -eq "$ROOT_UID" ]; then E_message "${E_ROOT}"; echo; exit 1; else return 0; fi
}

message()       # echo a simply formatted message (arg $1) to the screen
{ echo -e "${BGon}*${Boff} ${1}" && return 0 || return 1; }

message_n()     # echo -n a simply formatted message (arg $1) to the screen
{ echo -en "${BGon}*${Boff} ${1}" && return 0 || return 1; }

E_message()     # echo a simply formatted error message (arg $1) to the screen
{ echo -e "${BRon}*${Boff} ${1}" && return 0 || return 1; }

d_message()   { [ $VERBOSE ] && message "$@"; }
d_message_n() { [ $VERBOSE ] && message_n "$@"; }
dE_message()  { [ $VERBOSE ] && E_message "$@"; }
d_echo()      { [ $VERBOSE ] && echo "$@"; }
status_color() { case $1 in [yY1]|$TRUE) echo -en ${BGon};; [nN0]|$FALSE) \
                   echo -en ${BRon};; *) echo -en ${BYon};; esac; }

TrueFalse()   # echo to stdout "True" or "False", depending on truth of arg $1
{  [[ $1 ]] && echo -en "True" || echo -en "False" ; }

repeat()        # output a repeated string of character (arg $1) of length (arg $2)
{
  local i thing limit
  thing="$1"; limit=$2; out_str=""; i=0
  while [ $i -lt $limit ]; do out_str="${out_str}${thing}"; let "i++"; done
  echo -en "$out_str" && return 0 || return 1
}

prompt()        # set external variable $answer based on reponse to prompt $1
{ ps=$1; SCP; echo -en "$ps [Y/n]: "
  while read answer && [[ ! "${answer:0:1}" =~ [yYnN] ]];  # answer not a regex match
    do case ${answer:0:1} in [yY1]|"$TRUE") answer="n";; [nN0]|"$FALSE") answer="x";; esac
  RCP; echo -en "$(repeat ' ' $(termwidth))"; RCP; message_n "$ps [Y/n]: " ; done; }

termwidth()     # calculate and output the width of the terminal
{ echo -n $(stty size | sed 's/[0-9]* *//') && return 0 || return 1; }

termheight()    # calculate and output the height of the terminal
{ echo -n $(stty size | cut -d' ' -f1) && return 0 || return 1; }

separator()     # draw a horizontal line with a simple title (arg $1) and preface (arg $2)
{
  # to facilitate separation of portions of the output of various scripts
  # include a title preface (arg $2 or $(hostname) if $2 is not provided
  local msg preface msg_len
  [ ! -z "$2" ] && preface="$2" || preface=$(hostname)
  msg="${BYon}---[${BRon} $preface ${LBon}$1 ${BYon}]"
  msg_len=$(( ${#msg} - $(( ${#BYon} + ${#BRon} + ${#BBon} + ${#BYon} + ${#Boff} )) ))
  echo -en "$msg" && \
  echo -n $(repeat "-" $(( $(termwidth) - $(( $msg_len + ${#Boff} )) )) ) && echo -e ${Boff} && \
  return 0 || return 1
}

right_status()  # output a boolean status ($1) at the right margin
{
  # test with:
  #    echo -n "j" 2>/dev/null ; right_status $?
  #    ecko -n "j" 2>/dev/null ; right_status $?
  local status msg lpad rpad
  status=$1
  if [ $status -eq 0 ]; then
    msg="${BGon}Ok${Boff}"; lpad=2; rpad=2
  else
    msg="${BRon}Fail${Boff}"; lpad=1; rpad=1
  fi
  msg="${BBon}[$(repeat ' ' $lpad)${msg}$(repeat ' ' $rpad)${BBon}]${Boff}"
  msg_len=$(( ${#msg} - $(( ${#BGon} + $(( ${#BBon} * 2 )) + $(( ${#Boff} * 2 )) )) ))
  # first find a reference point by returning to the beginning of the line, *then*
  #   use the cursor forward command defined above to move to the position calculated using
  #   the terminal width function defined above, and print the message at the right margin
  echo -en "\r" && \
  CUF $(( $(termwidth) - $msg_len -1 )) && \
  echo -e "$msg" && \
  return 0 || return 1
}

vercomp()      # compare two version numbers return [0:equal|1:greaterthan|2:lessthan]
{ if [[ "$1" == "$2" ]]; then return 0; else first=$(echo -en "$1\n$2" | sort -V | head -n1);
  [[ "$first" == "$2" ]] && return 1 || return 2; fi }

check_write_laymanconf() {
#-----[ local definitions and variables ]---------------------------------------
# check and reqwrite /etc/portage/repos.conf/layman.conf

tempfile=$(mktemp -p "/var/tmp/" -t "laymanconf.XXXX")
targetfile="$layman_conf"
target_section="$repo_name"

HEADING=$FALSE
TARGET=$FALSE

#-----[ main of check_write_laymanconf ]-------------------------------------------------------------------
separator '(beta)' "check_write_laymanconf"

# parameters representing the current contents of the target section of the cfg
# initialize the parameter_list
parameter_list=(priority location layman-type sync-type sync-uri branch auto-sync)

# initialize the values associated with these parameters
for ((i=0; i<${#parameter_list[@]}; i++)); do val[i]=""; done

# valid values to which we will compare/set the parameters in the target section of the cfg
valid=("$my_priority" "$my_location" "$my_layman_type" "$my_sync_type" "$my_sync_uri" "$my_branch" "$my_auto_sync")
# display this
message "Here are the initialized parameter settings:"
for ((i=0; i<${#parameter_list[@]}; i++)); do echo -e "  i=[$i] parameter[$i]=[${parameter_list[i]}], \tval[$i]=[${val[i]}], \tvalid[$i]=[${valid[i]}]"; done
echo

line_number=0
echo -e "# layman.conf remote overlay [$target_section] revalidated by check_write_laymancfg (brendlfly) $(my_short_date)" > $tempfile
while read line
do
  let "line_number++"; d_message_n "${BYon}Line [$line_number]${Boff} "
  d_message "line=[${BMon}$line${Boff}], length=[${#line}]"
  # set flags to track when we've found a section and if that is our target section
  [[ "${line:0:1}" == "[" ]] && HEADING=$TRUE || HEADING=$FALSE
  if [[ $HEADING ]]
  then
    if [[ "${line}" == "[${target_section}]" ]]
    then
      TARGET=$TRUE
    else
      TARGET=$FALSE
    fi
  fi
  d_message_n "  $(status_color $HEADING)HEADING=[$HEADING]${Boff}, "
  d_echo -e "$(status_color $TARGET)TARGET=[$TARGET]"

  # if this line is not a section heading or blank line, carefully extract the parameter name and value
  if [[ ! $HEADING ]] && [[ ! -z $line ]]
  then
    parameter=$(echo $line | cut -d'=' -f1 | sed 's/[ \t]*$//' | sed 's/^[ \t]*//')
    value=$(echo $line | cut -d'=' -f2 | sed 's/[ \t]*$//' | sed 's/^[ \t]*//')
    d_message "    parameter=[$parameter], value=[$value]"
  else # it's either a section heading or a blank line, so null the parameter and value
    parameter=""
    value=""
    d_message "    (section heading) parameter=[$parameter], value=[$value]"
  fi

  # if we are not in the target section, then just copy this line out to the new config
  if [[ ! $TARGET ]]
  then  # if this is a section heading, precede it with a blank line
#    [[ ${HEADING} ]] && [[ "${line_number}" != "1" ]] && \
    [[ $HEADING ]] && \
      echo >> $tempfile && dE_message "    printing blank line before section heading"
    [[ "$line" != "" ]] && echo $line >> $tempfile && \
      d_message "    copying (non-target) \"$line\" to new config file"
  else # target == true, and since we are in the target section, inspect all parameters
    # if this is the [target_section] line itself, then just copy it out
    if [[ "${line}" == "[${target_section}]" ]]
    then
      dE_message "    copying (target section heading) \"$line\" to new config file after newline"
      echo -e "\n$line" >> $tempfile
      # I'm going to write all the valid settings I know, and copy from the file, only the ones I do not recognize
      # (replace the known parameter entries of the PREVIOUS (target) section with valid parameters)
      d_message "  ${LBon}Replacing the known parameter entries of the PREVIOUS [$target_section] section with valid parameters${Boff}"
      for ((i=0; i<${#parameter_list[@]}; i++))
      do
        newline="${parameter_list[i]} = ${valid[i]}" && echo $newline >> $tempfile && \
       	dE_message "    appending (known parameter) \"$newline\" to new config file"
      done
    else
      # ignore this line of the target section if I recognize the parameter
      # (set the value to null, so it will be recognized as invalid and will not be transferred to the new config)
      for ((i=0; i<${#parameter_list[@]}; i++))
      do
        [[ "$parameter" == "${parameter_list[i]}" ]] && value="" && val[i]=""
      done
      # copy out lines from the target secton if I do not recognize the parameter (didn't blank out the value)
      d_message "    (post-edit) parameter=[$parameter], value=[$value]"
      if [[ "$(echo $value | sed 's/[ \t]*$//' | sed 's/^[ \t]*//')" != "" ]]
      then
        d_message "    parameter[$parameter], value=[$value] (non-blank); copying (in target section) \"$line\" to new config file"
        echo $line >> $tempfile
      else
        d_message "    parameter[$parameter], value=[$value] (was blank, or made blank to ignore as a known parameter); not writing anything at this time"
      fi # blank or non-blank
    fi # target section heading line or not
  fi # target section or not
done < $targetfile

echo; separator "New Config " " "; cat $tempfile
if [[ $DIFF ]]; then separator "$targetfile $tempfile" "diff"; diff $targetfile $tempfile; message "-----[ done diff]-----\n"; fi
if [[ $INSTALL ]]
then
  answer="x"
  prompt "${BRon} Overwrite ${BWon}$targetfile ${BYon}with ${BWon}$tempfile ${BYon}?${Boff}"
  if [[ "$answer" == "y" ]]
  then
    message 'OK, About to "cp -v $tempfile $targetfile"'
    cp -v $tempfile $targetfile
  else
    d_message "answer=[$answer]"
    message "OK, I won't do it"
  fi
fi
message_n "Cleaning up from layman.conf edit..." && rm $tempfile; right_status $?

}  # end of check_write_laymanconf

check_write_laymancfg() {
#-----[ local definitions and variables ]---------------------------------------
tempfile=$(mktemp -p "/var/tmp/" -t "laymancfg.XXXX")
targetfile="$layman_cfg"
target_section="overlays"

HEADING=$FALSE
TARGET=$FALSE
ALREADY_HAS_IT=$FALSE

#-----[ main - check_write_laymancfg ]-------------------------------------------
separator '(beta)' "check_write_laymancfg"

# start with an empty $tempfile
echo -n "" > $tempfile

message "I will now ensure the overlay [$repo_name] is in the remotes list ($targetfile)"
# if it's already there, do nothing; otherwise insert it in the "overlay" section
# Note: the current format has 1st line [MAIN]; then openning comments (make our mark after those)

# Technique comment: First, the whitespace-trimming problem: the read command automatically
#   trims leading and trailing whitespace; this can be fixed by changing its definition of
#    whitespace by setting the IFS variable to blank. Also, read assumes that a backslash
#    at the end of the line means the next line is a continuation, and should be spliced
#    together with this one; to fix this, use its -r (raw) flag. The third problem here is
#    that many implementations of echo interpret escape sequences in the string (e.g. they
#    may turn \n into an actual newline); to fix this, use printf instead.
#  e.g. to get a blank line after the output line:
#    # while IFS='' read -r line; do  printf "%s\n\n" "$line">>$OUTPUT; done <$f

OPENNING=$TRUE
line_number=0
while IFS='' read -r record
do
  let "line_number++"
  # trim whitespace (sed should not be needed since echo probably does this, but I want to ensure)
  line=$( echo $record | sed 's/[ \t]*$//' | sed 's/^[ \t]*//' )
  LINE=($line); PARTS=${#LINE[@]}
  length=${#line}
  d_message_n "${BYon}Line [$line_number]${Boff} "
  d_echo -en "line=[${BMon}$line${Boff}], length=[$length], "
  d_echo -e "PARTS=[$PARTS], PART1=[${LINE[0]}], PART2=[${LINE[1]}]"
  # if we've reached the end of the openning comments (1st blank line after)
  # then make our mark followed by the blank line
  if [[ $OPENNING ]]
  then
    if [[ "$length" == "0" ]] # end of the opening
    then
      echo -e "# layman.cfg remote overlay [$target_section] revalidated by check_write_laymancfg (brendlfly) $(my_short_date)\n" >> $tempfile && \
        dE_message "    inserted marking with timestamp as final comment line in openning comments"
      OPENNING=$FALSE
    else  # non-blank openning line - just copy it
      printf "%s\n" "$record" >> $tempfile && \
        d_message "    copying (openning line) to new config file"
    fi
  else  # no longer in the openning comments
    # set flags - is this a heading line; is it our target section's heading?
    # in this config file format, a heading is marked by one non-commented word followed by
    # whitespace and a colon (e.g. "overlay   :" which marks our target)
    if [[ "$PARTS" == "2" && "${LINE[1]}" == ":" && "${LINE[0]:0:1}" != "#" ]]  # markings of a section heading
    then
      HEADING=$TRUE
      dE_message "${LBon}    About to compare [${LINE[0]}] to [${target_section}]${Boff}"
      if [[ "${LINE[0]}" == "${target_section}" ]]
      then
        TARGET=$TRUE
        # we are nested in HEADNG=$TRUE, so this is our target heading, print it out just like we found it
        printf "%s\n" "$record" >> $tempfile && \
          dE_message " ** TARGET set. copying (target section heading) to new config file"
      else
        TARGET=$FALSE
        # either way, since not our target, print it out just like we found it and be done with it
        printf "%s\n" "$record" >> $tempfile && \
          d_message " ** TARGET not set. copying (non-target section heading) to new config file"
      fi  # HEADING yes, TARGET or not
    else
      HEADING=$FALSE
      if [[ ! $TARGET ]]
      then  # not in the target section
        #  just print this out like we found it
        printf "%s\n" "$record" >> $tempfile && \
          d_message "    copying (non-target non-heading line) to new config file"
      else  # yes we're in the target section, and this is not a heading line
        # insert our new content BEFORE the first BLANK like following the target heading
        if [[ "$length" != "0" ]]
        then # this line's not blank, just print it like we found it
          printf "%s\n" "$record" >> $tempfile && \
            dE_message "    copying (non-blank target line) to new config file"
          # if this line IS the line we would add (i.e. it is already there), then take note so we don't add it again
          if [[ "$line" == "${overlay_url}" ]]
          then
            ALREADY_HAS_IT=$TRUE
            dE_message "${BRon}Found it!${Boff}"
          else
            dE_message "${BYon}I checked, this is not it${Boff}"
          fi
        else # this line IS blank, so insert our new line, then print blank line
          if [[ ! $ALREADY_HAS_IT ]]
          then
            newline="\t${overlay_url}\n"
#            printf "%s\n\n" "${newline}" >> $tempfile && \
            echo -e "${newline}" >> $tempfile && \
              message "    ${BYon}inserting (NEW line) with new content and blank line, to new config file${Boff}"
          else
            message "    ${BGon}Already good.  inserting only blank line, to new config file${Boff}"
          fi
          TARGET=$FALSE   # we are no longer in the target section
        fi  # blank line or not
      fi  # HEADING no, TARGET or not
    fi  # HEADING or not
  fi  # OPENNING or not
  d_message_n "  $(status_color $OPENNING)OPENNING=[$(TrueFalse $OPENNING)]${Boff}, "
  d_echo -en "$(status_color $HEADING)HEADING=[$(TrueFalse $HEADING)], "
  d_echo -e "$(status_color $TARGET)TARGET=[$(TrueFalse $TARGET)]"
done < $targetfile
# Note: if we got all the way here and did not find the target, we need to create it with appropriate content
# TODO -- a better placement would be at the point in the fle where it is supposed to belong
#   I would need to keep an eye out for the preceeding and following sections ( somewhat difficult since many lines
#   both before and after are commented out.  The best way may be to actually "look for '$target_section' in the comments,"
#   and print those out, looking for the heading, eating and printing blank lines... if we get to another non-blank line
#   before the "$target_section heading", then insert
#   ** alternatively, I could make TWO passes -- one "read" pass, to separate the "before" and "after" content, and to
#   extract and consolidate the part(s) which pertain to our section, then on the second pass, write the destination (temp) file
#   this could require four temp files (1) before_content, (2) my_section's proper content, (3) after_content, and 
#   (4) $tempfile (temp target destination)

echo; separator "New Config " " "; cat $tempfile
if [[ $DIFF ]]; then separator "$targetfile $tempfile" "diff"; diff $targetfile $tempfile; message "-----[ done diff]-----\n"; fi
if [[ $INSTALL ]]
then
  answer="x"
  prompt "${BYon}Confirm${Boff} -${BRon} Overwrite ${Boff}$targetfile ${BYon}with ${Boff}$tempfile ${BYon}?${Boff}"
  if [[ "$answer" != "n" ]]
  then
    message 'OK, About to "cp -v $tempfile $targetfile"'
    cp -v $tempfile $targetfile
  else
    message "OK, I won't do it"
  fi
fi
message_n "Cleaning up from layman.cfg edit..." && rm $tempfile; right_status $?

}  # end of check_write_laymancfg

#-----[ main script - of hookup_remote_overlay.sh ]----------------------------------------------------------------
checkroot
separator "hookup_remote_overlay.sh-$BUILD"

# note that the flags set by this process will be applied "globally" within the scope of hookup_remote_overlay.sh
my_args="$@"
d_message "${BMon}Processing Arguments: [$my_args]${Boff}"
process_arguments $my_args; [[ "$?" != "0" ]] && exit 1
message_n "${BYon}Flags:  ${BWon}INSTALL=[$(status_color $INSTALL)$(TrueFalse $INSTALL)${BWon}],  "
echo -en "DIFF=[$(status_color $DIFF)$(TrueFalse $DIFF)${BWon}],  "
echo -e "VERBOSE=[$(status_color $VERBOSE)$(TrueFalse $VERBOSE)${BWon}]${Boff}"
echo
message_n "Checking for app-portage/layman..."
#layman_check_strlayman_check_str=$(eix '-ecI' layman --format '<installedversions:NAMEVERSION>') 2>/dev/null
layman_check_str=$(equery -q list --format='$cpv' layman)
if [[ -z "$layman_check_str" ]]
then
  right_status $?
  d_message "equery returned layman_check_str=[$layman_check_str]"
  message "app-portage/layman not found, installing"
  keyword_and_emerge_layman
else
  right_status $?
  d_message "equery returned layman_check_str=[$layman_check_str]"
  message "$layman_check_str is installed. checking whether version is at least 2.1.0..."
  layman_ver=$(qatom $layman_check_str | awk '{print $3 "-" $4}')
  if [[ ! $? ]]
  then
    E_message "Error: qatom failed to return valid layman_ver"; exit 1
  fi
  vercomp $layman_ver 2.1.0
  case $? in
    [0,1]) # equal or greater
      message "Found $layman_check_str to be >= 2.1.0; continuing..." ;;
    2) # lesser
      message "Found $layman_check_str to be < 2.1.0; reinstalling..."
      keyword_and_emerge_layman ;;
    *) # error
      message "Could not properly compare $layman_check_str to 2.1.0; reinstalling..."
      keyword_and_emerge_layman ;;
  esac
fi

echo
message "Now linking ${repo_name} to the remote github sources with layman..."
message "${BYon}(Say \"y\"(es) to accept this overlay as \"unofficial\")${Boff}"
layman -o https://raw.githubusercontent.com/JosephBrendler/joetoo/master/repositories.xml \
  -f -a joetoo -q

echo
message_n "checking /etc/layman/layman.cfg..."
conf_type=$(grep -s "conf_type :" /etc/layman/layman.cfg | cut -d: -f2 | sed 's/^ //')
[[ "$conf_type" == "repos.conf" ]] ; right_status $?
if [[ "$conf_type" != "repos.conf" ]]
then
  E_message "Error: /etc/layman/layman.cfg not using 'conf_type : repos.conf'"
  exit 1
else
  message_n "Checking /etc/portage/repos.conf..."
  [[ -d /etc/portage/repos.conf ]] ; right_status $?
  if [[ ! -d /etc/portage/repos.conf ]]
  then
    message "Creating /etc/portage/repos.conf..."
    mkdir -v /etc/portage/repos.conf
    # create the standard gentoo.conf while we're at it
    echo -e "[DEFAULT]\nmain-repo = gentoo\n\n[gentoo]\nlocation = /usr/portage\nsync-uri = rsync://rsync.namerica.gentoo.org/gentoo-portage\nsync-type = rsync\nauto-sync = yes" > /etc/portage/repos.conf/gentoo.conf && \
      message "Successfully created /etc/portage/repos.conf/gentoo.conf:" && cat /etc/portage/repos.conf/gentoo.conf || \
      E_message "Error, failed to create /etc/portage/repos.conf/gentoo.conf"
  else
    message "/etc/portage/repos.conf already exists; continuing..."
  fi
  message "(re)Building layman's entry in repo.conf..."
  layman-updater -R
  # make sure the repos.conf/layman.conf has right params (priority, sync-uri, and sync-type, etc.)
  check_write_laymanconf
fi
# make sure the /etc/layman/layman.cfg includes our overlay in the "remotes list"
check_write_laymancfg

echo
# Note: with -p, mkdir command creates the parent repo_name directory as well as its children
message "Now checking setup of profiles and metadata files for ${repo_name}..."
repo_profiles="${repo_location}/${repo_name}/profiles"
repo_profiles_file="${repo_profiles}/repo_name"
repo_profiles_file_content="${repo_name}"
repo_metadata="${repo_location}/${repo_name}/metadata"
repo_metadata_file="${repo_metadata}/layout.conf"
repo_metadata_file_content="masters = gentoo"

# First for profiles -- check for directory
if [ -d ${repo_profiles} ]
then
  # check for file
  if [ -f ${repo_profiles_file} ]
  then
    # check for file content
    result=$(grep "${repo_profiles_file_content}" ${repo_profiles_file})
    message "Result of check for right content: [${result}]"
    if [ -z "${result}" ]
    then
      # ust add the right content
      echo "${repo_profiles_file_content}" >> ${repo_profiles_file} && \
        message "Successfully populated pre-existing ${repo_profiles_file} with new content \"${repo_profiles_file_content}\"" || \
        E_message "Error populating pre-existing ${repo_profiles_file} with content \"${repo_profiles_file_content}\""
    else
      # file already had right content
      message "${repo_profiles_file} already exists, with content \"${repo_profiles_file_content}\" continuing..."
    fi
  else
    # create file with right content
    echo "${repo_profiles_file_content}" > ${repo_profiles_file} && \
      message "successfully created ${repo_profiles_file} and added content \"${repo_profiles_file_content}\"" ||
      E_message "Error just creating file ${repo_profiles_file} with content \"${repo_profiles_file_content}\""
  fi
else
   # create directory (and file with right content)
  mkdir -pv ${repo_profiles} && \
    message "Successfully created directory ${repo_profiles}" || \
    E_message "Error creating directory ${repo_profiles}"
  echo "${repo_profiles_file_content}" > ${repo_profiles_file} && \
    message "successfully created ${repo_profiles_file} with content \"${repo_profiles_file_content}\"" || \
    E_message "Error creating file ${repo_profiles_file} with content \"${repo_profiles_file_content}\""
fi

# Next for metadata -- check for directory
if [ -d ${repo_metadata} ]
then
  # check for file
  if [ -f ${repo_metadata_file} ]
  then
    # check for file content
    result=$(grep "${repo_metadata_file_content}" ${repo_metadata_file})
    message "Result of check for right content: [${result}]"
    if [ -z "${result}" ]
    then
      # ust add the right content
      echo "${repo_metadata_file_content}" >> ${repo_metadata_file} && \
        message "Successfully populated pre-existing ${repo_metadata_file} with new content \"${repo_metadata_file_content}\"" || \
        E_message "Error populating pre-existing ${repo_metadata_file} with content \"${repo_metadata_file_content}\""
    else
      # file already had right content
      message "${repo_metadata_file} already exists, with content \"${repo_metadata_file_content}\" continuing..."
    fi
  else
    # create file with right content
    echo "${repo_metadata_file_content}" > ${repo_metadata_file} && \
      message "successfully created ${repo_metadata_file} and added content \"${repo_metadata_file_content}\"" ||
      E_message "Error just creating file ${repo_metadata_file} with content \"${repo_metadata_file_content}\""
  fi
else
   # create directory (and file with right content)
  mkdir -pv ${repo_metadata} && \
    message "Successfully created directory ${repo_metadata}" || \
    E_message "Error creating directory ${repo_metadata}"
  echo "${repo_metadata_file_content}" > ${repo_metadata_file} && \
    message "successfully created ${repo_metadata_file} with content \"${repo_metadata_file_content}\"" || \
    E_message "Error creating file ${repo_metadata_file} with content \"${repo_metadata_file_content}\""
fi

echo
message "${LBon}The remote overlay \"joetoo\" has been installed.${Boff}"
message "The following package(s) in the \"joetoo\" repository have ${BGon}already been installed${Boff}:"
equery -q has repository joetoo
message "The following package(s) in the \"joetoo\" repository have ${BRon}not yet been installed:${Boff}"
equery -q has -o -I repository joetoo
echo
message "---[ Done ]---"
echo
