#!/bin/sh

# source the main header (which in turn sources the _unicode library)
. /usr/sbin/script_header_joetoo

# filter the file and pipe it into the loop
grep -Ev "^(\s*$|#)" /usr/sbin/script_header_joetoo_unicode | while read -r _item; do
    # extract variable name (everything before the =)
    _name="${_item%%=*}"
    # get the raw \Uxxxx value from the environment
    eval "_raw_val=\"\$$_name\""
    # cook the hex into a binary character using your existing logic
    _cooked_val=$(u_hex_to_octal "$_raw_val")
    # print the label and the rendered glyph
    LC_CTYPE=en_US.utf8 printf '%-30s: %b\n' "$_name" "$_cooked_val"
    # clean up local loop variables
    unset _name _raw_val _cooked_valdone
done
