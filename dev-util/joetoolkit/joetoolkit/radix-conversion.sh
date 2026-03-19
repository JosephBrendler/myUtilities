#!/bin/sh
. /usr/sbin/script_header_joetoo || { printf '%s\n' "error: failed to source /usr/sbin/script_header_joetoo"; exit 1 ; }
if ! command -v j_msg >/dev/null 2>&1; then printf '%s\n' "error: cannot find command j_msg"; exit 2 ; fi

#-----[ variables ]------------------------------------
binary_chars="01\."
decimal_chars="0123456789\."
hex_chars="0123456789abcdefABCDEF\."
octal_chars="01234567"
allowed_bases="dbho"

filtered_string=""

#-----[ functions ]------------------------------------

b2d() {
    float_num=$1
    new_num=$(printf '%s\n' "scale=10; obase=10; ibase=2; $float_num" | bc)
    j_msg -p "decimal: $new_num"
}

b2o() {
    float_num=$1
    new_num=$(printf '%s\n' "scale=10; obase=8; ibase=2; $float_num" | bc)
    j_msg -p "octal: $new_num"
}

b2h(){
    float_num=$1
    new_num=$(printf '%s\n' "scale=10; obase=16; ibase=2; $float_num" | bc)
    j_msg -p "hex: $new_num"
}

o2b() {
    float_num=$1
    bin_num=$(printf '%s\n' "scale=10; obase=2; ibase=8; $float_num" | bc)
    j_msg -p "binary: $bin_num"
}

o2d() {
    float_num=$1
    new_num=$(printf '%s\n' "scale=10; obase=10; ibase=8; $float_num" | bc)
    j_msg -p "decimal: $new_num"
}

o2h() {
    float_num=$1
    new_num=$(printf '%s\n' "scale=10; obase=16; ibase=8; $float_num" | bc)
    j_msg -p "hex: $new_num"
}

d2b() {
    float_num=$1
    bin_num=$(printf '%s\n' "scale=10; obase=2; ibase=10; $float_num" | bc)
    j_msg -p "binary: $bin_num"
}

d2o() {
    float_num=$1
    new_num=$(printf '%s\n' "scale=10; obase=8; ibase=10; $float_num" | bc)
    j_msg -p "octal: $new_num"
}

d2h() {
    float_num=$1
    new_num=$(printf '%s\n' "scale=10; obase=16; ibase=10; $float_num" | bc)
    j_msg -p "hex: $new_num"
}

h2b() {
    float_num=$1
    float_num=$(printf '%s' "$float_num" | tr 'a-f' 'A-F')
    bin_num=$(printf '%s\n' "scale=10; obase=2; ibase=16; $float_num" | bc)
    j_msg -p "binary: $bin_num"
}

h2o() {
    float_num=$1
    float_num=$(printf '%s' "$float_num" | tr 'a-f' 'A-F')
    new_num=$(printf '%s\n' "scale=10; obase=8; ibase=16; $float_num" | bc)
    j_msg -p "binary: $new_num"
}

h2d(){
    float_num=$1
    float_num=$(printf '%s' "$float_num" | tr 'a-f' 'A-F')
    new_num=$(printf '%s\n' "scale=10; obase=10; ibase=16; $float_num" | bc)
    j_msg -p "decimal: $new_num"
}

usage() {
    j_msg -p "Usage:  ${Gon}dbh-conversion ${Mon}<number> ${Con}[<out_base>]${Boff}"
    j_msg -p "  input \$1 can be floating point, binary, decimal, or hex"
    j_msg -p "  Specify input base with \"<base>#\" convention; examples --"
    j_msg -p "    2#101.01 (base 2)"
    j_msg -p "    8#77.63 (base 8)"
    j_msg -p "    16#FF.2A (base 16)"
    j_msg -p "    36#abc.0c (base 36)"
    j_msg -p "  out_base \$2 can be b|2, d|10, or h|16"
    exit 1
}

#-----[ main script ]----------------------------------

# one (inputnumber) or two (inputnumber OBASE) allowed
[ $# -gt 2 ] && usage # guard: no more than 2 args
[ $# -lt 1 ] && usage # guard: no less than 1 arg
OBASE="${2:-d}"       # guard: if no $2, default OBASE to decimal

# $2 specifies OBASE; default to decimal
if [ $# -eq 2 ] ; then
    case "$OBASE" in
        b|d|h|o) : ;; # already good
        2    ) OBASE="b" ;;
        8    ) OBASE="o" ;;
        10   ) OBASE="d" ;;
        16   ) OBASE="h" ;;
        *       ) j_msg -p "${err:+-$err}" "Invalid output base"; usabe ;;
    esac
fi

# sanity check OBASE
input_string="$OBASE"
case "$OBASE" in
  d|b|h|o) : ;; # do nothing (goog)
  *    ) j_msg -p "${err:+-$err}" "invalid OBASE: [ $OBASE ]" ; usage ;;
esac
j_msg -p "${debug:+-$debug}" "OBASE: [ $OBASE ]"

# get input base
case "$1" in
  *"#"* )
    # there is a # - figure out base
    input_base="${1%#*}" # extract bb from bb#nnnn
    case "$input_base" in
        "2"  ) IBASE="b" ;;
        "8"  ) IBASE="o" ;;
        "10" ) IBASE="d" ;;
        "16" ) IBASE="h" ;;
        *    ) j_msg -p "${err:+-$err}" "invlid input base: [ $input_base ]"; usage ;;
    esac
    ;;
  * )
    # there is no # - assume decimal
    IBASE="d"
    ;;
esac
j_msg -p "${debug:+-$debug}" "IBASE: [ $IBASE ]"

# sanity check input number digits
input_string="${1#*#}"   # extract nnnn from bb#nnnn
j_msg -p "${debug:+-$debug}" "just set input_string = [ $input_string ]"

case "$IBASE" in
    "b" )
      case "$input_string" in
        *[!01.]* )
          j_msg -p "${err:+-$err}" "non-binary digits in input_string: [ $input_string ]"
          exit 1
          ;;
      esac ;;
    "o" )
      case "$input_string" in
        *[!0-7]* )
          j_msg -p "${err:+-$err}" "non-octal digits in input_string: [ $input_string ]"
          exit 1
          ;;
      esac ;;
    "d" )
      case "$input_string" in
        *[!0-9.]* )
          j_msg -p "${err:+-$err}" "non-decimal digits in input_string: [ $input_string ]"
          exit 1
          ;;
      esac ;;
    "h" )
      case "$input_string" in
        *[!0-9a-fA-F.]* )
          j_msg -p "${err:+-$err}" "non-hex digits in input_string: [ $input_string ]"
          exit 1
          ;;
      esac ;;
    *   ) j_msg -p "${err:+-$err}" "invalid IBASE: [ $IBASE ]" ; usage ;;
esac

j_msg -p "${debug:+-$debug}" "about to run ${Gon}${IBASE}2${OBASE} ${Con}${input_string}${Boff}"
func="${IBASE}2${OBASE}"
"$func" "${input_string}"
