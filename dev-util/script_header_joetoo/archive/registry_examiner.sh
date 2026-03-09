#!/bin/sh

. /usr/sbin/script_header_joetoo

PN=${0##*/}

# print index, name, emoju, bytes for diagnostics
# e.g. => emoji (30) [tree_evergreen] 🌲   0000000 f0 9f 8c b2
#j_msg -M 27 "old diagnotic"
#for idx in $(seq 1 40); do
#  printf '%s' "emoji ($idx) [$(name_of_emoji $idx)] ";
#  eval "emoji_safe \$$(name_of_emoji $idx)";
#  echo -n "   ";
#  eval "emoji_safe \$$(name_of_emoji $idx) | od -t x1 | head -n1";
##  echo;
#done

_examine_registry()
{ dr_ret=0;   _dr_REGISTRY=$1
  # use while read rather than for ... in to manage word splitting; use heredoc rather than | to avoid subshell variable trap
  # (careful: heredoc lines must be at left edge of screen)
  # first pass - read variable lengths for alignment
  _dr_longest_idx=0; _dr_longest_name=0; _dr_longest_var=0; _dr_longest_label=0
  while IFS= read -r _dr_line; do
  #  echo "_dr_line: $_dr_line"
    [ -z "$_dr_line" ] && continue  # Skip empty lines
    # read US separated fields into variables
    IFS="$US" read -r _dr_idx _dr_name _dr_var _dr_label <<EOF
$_dr_line
EOF
#echo "_dr_idx: [$_dr_idx]; _dr_longest_idx: [$_dr_longest_idx]; dr_idx len: [${#_dr_idx}]"
    [ "${#_dr_idx}" -gt "$_dr_longest_idx" ] && _dr_longest_idx="${#_dr_idx}"
    [ "${#_dr_name}" -gt "$_dr_longest_name" ] && _dr_longest_name="${#_dr_name}"
    [ "${#_dr_var}" -gt "$_dr_longest_var" ] && _dr_longest_var="${#_dr_var}"
    [ "${#_dr_label}" -gt "$_dr_longest_label" ] && _dr_longest_label="${#_dr_label}"
  done<<EOF
$(printf '%s\n' "$_dr_REGISTRY")
EOF

  # second pass - print diagnostic data for emoji registry: index, name, emoju, bytes | then cooked form emoji and its bytes
  #printf '%s\n' "$ACTIVE_EMOJI_REGISTRY" | while IFS= read -r _dr_line; do
  #for _dr_line in "$ACTIVE_EMOJI_REGISTRY"; do
  while IFS= read -r _dr_line; do
  #  echo "_dr_line: $_dr_line"
    [ -z "$_dr_line" ] && continue  # Skip empty lines
    # read US separated fields into variables
    # (careful: heredoc lines must be at left edge of screen)
    IFS="$US" read -r _dr_idx _dr_name _dr_var _dr_label <<EOF
$_dr_line
EOF

#echo "_dr_label: [$_dr_label]; _dr_longest_label: [$_dr_longest_label]; dr_label len: [${#_dr_label}]"
    # emit registry data
    repeat ' ' $(( _dr_longest_idx - ${#_dr_idx} ))  # PRE space-pad idx w no extra
    printf '%s:' "$_dr_idx"
    printf ' %s ' "$_dr_name"
    repeat '.' $(( _dr_longest_name - ${#_dr_name} ))  # .-pad name w no extra
    printf ' %s  ' "$_dr_label"
    # emit emoji
    emoji_safe "$_dr_var"; printf ' '
    # dump bytes
    emoji_safe "$_dr_var" | od -An -t x1 | head -n1 | tr -d '\n'
    eval "printf '  precooked: %b' \"\$bin_$_dr_name\""
    eval "printf '%b' \"\$bin_$_dr_name\"" | od -An -t x1 | head -n1
  #  printf '\n'
  done<<EOF
$(printf '%s\n' "$_dr_REGISTRY")
EOF

  unset -v _dr_REGISTRY _dr_line _dr_idx _dr_name _dr_var _dr_label
}

#-----[ main function ]--------------------------------------------------------
separator "$(hostname)" "$PN"
j_msg -M 27 "Starging diagnotics ..."
separator "$PN" "(ACTIVE_EMOJI_REGISTRY)"
_examine_registry "$ACTIVE_EMOJI_REGISTRY"
separator "$PN" "(ACTIVE_UI_BOX_REGISTRY)"
_examine_registry "$ACTIVE_UI_BOX_REGISTRY"


separator "$PN" "(severity levels)"
# print diagnostic data for severity-level emoji prefixes
for _SEVERITY in $(seq 0 7); do
  # this case block is copied from emit()
  case "$_SEVERITY" in
    0|1)   premoji_idx="$idx_severity_01_emoji" ;;  # Emerg, Alert ,...... cross_mark
    2|3)   premoji_idx="$idx_severity_23_emoji" ;;  # Error, Critical .... explosion
    4)     premoji_idx="$idx_severity_4_emoji" ;;   # Warning ............ no_entry
    5)     premoji_idx="$idx_severity_5_emoji" ;;   # Notice ............. face_thinking
    6)     premoji_idx="$idx_severity_6_emoji" ;;   # Info ............... face_grin
    7)     premoji_idx="$idx_severity_7_emoji" ;;   # Debug .............. magnifying_glass_left
  esac
  _msg="test at severity (${_SEVERITY})"
  _msg="${_msg} [$(get_severity "${_SEVERITY}")] ||"
  _msg="${_msg}  emoji prefix should be [$(name_of_emoji "$premoji_idx")]"
  DEBUG="$TRUE" j_msg -"${_SEVERITY}" "$_msg";
done

