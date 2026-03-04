#!/bin/sh

# source the main header (which in turn sources the _unicode library)
. /usr/sbin/script_header_joetoo
export _names=""
# filter the file and pipe it into the loop to get the list of names
while read -r _item; do
    # extract variable name (everything before the =)
    _name="${_item%%=*}"
    _names="${_names} ${_name}"
done<< EOF
$(grep -Ev "^(\s*$|#)" /usr/sbin/script_header_joetoo_unicode)
EOF
_longest=$(get_longest $_names)
_column_width=$(( _longest + 2 ))
_i=0
_name=""
grep -Ev "^(\s*$|#)" /usr/sbin/script_header_joetoo_unicode | while read -r _item; do
    # extract variable name (everything before the =)
    _name="${_item%%=*}"
    # get the raw \Uxxxx value from the environment
    eval "_raw_val=\"\$$_name\""
    # cook the hex into a binary character using your existing logic
    _cooked_val=$(u_hex_to_octal "$_raw_val")
    if [ $((_i % 2)) -eq 0 ]; then _clr="${BCon}"; else _clr="${BGon}"; fi
    # print the label and the rendered glyph
    _pad=$(repeat '.' $(( _column_width - ${#_name} -2 )))
    printf "${_clr}%s${_clr}%s${Boff}" "$_name" "${_pad}: "
    LC_CTYPE=en_US.utf8 printf '%b\n' "$_cooked_val"
    _i=$(( _i + 1 ))
done
# clean up local loop variables
unset _name _names _raw_val _cooked_valdone
