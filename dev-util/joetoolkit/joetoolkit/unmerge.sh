#!/bin/bash
# umerge.sh - unmerge packages easily
# v0.0.2b by Zucca, from Finland posted 15 Dec 16 at https://forums.gentoo.org/viewtopic-t-724325-highlight-.html

UNMERGELIST=$(mktemp -t "unmerge_list_XXXXX")

set -- $(while read LINE; do echo -n "$LINE | off "; done < /var/lib/portage/world | sort)

dialog --title 'Dialog unmerger' --single-quoted --checklist \
  'Select packages to unmerge' 0 0 0 \
  "$@" \
  2> "$UNMERGELIST"

clear

# remove single-quotes from the unmerge list
sed -i "s/'//g" $UNMERGELIST

emerge --deselect $(cat $UNMERGELIST)
emerge -av --depclean
revdep-rebuild

rm $UNMERGELIST
