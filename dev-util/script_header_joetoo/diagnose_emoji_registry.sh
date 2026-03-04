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

separator "$(hostname)" "$PN"
j_msg -M 27 "new diagnotic"
printf '%s\n' "$ACTIVE_EMOJI_REGISTRY" | while IFS= read -r line; do
#  echo "line: $line"
  # Skip empty lines
  [ -z "$line" ] && continue
  IFS="$US" read -r idx name var label <<EOF
$line
EOF
  # emit header
  printf 'emoji (%s) [%s] %s  ' "$idx" "$name" "$label"
  # emit emoji
  emoji_safe "$var"; printf ' '
  # dump bytes
  emoji_safe "$var" | od -t x1 | head -n1
#  printf '\n'
done
