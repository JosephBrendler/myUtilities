#!/bin/bash
# merge.sh - merge packages easily
# Version 0.0.2b by Zucca from Finland, posted 6 Jan 2009 at https://forums.gentoo.org/viewtopic-p-5368160.html

EIXOUTPUT=`eix -c --not -I '' $@ | grep '^\[.\] ' | sed -e 's/^.\{4\}//' -e "s/\"/'/g"`
# On above line I had to replace every " with '. I tried to escape but didn't work.

if [ `wc -c <<< "$EIXOUTPUT"` -gt 4 ]
then

    MERGELIST=`mktemp -t "merge_list_XXXXX"`

    while read LINE
    do
        echo -n "${LINE%% *} "
        echo -ne "\"${LINE#* }\" "
        echo "off"
    done <<< "$EIXOUTPUT" | xargs dialog --title 'Dialog merge' --single-quoted --checklist "Found `wc -l <<< "$EIXOUTPUT"` matches." 0 0 0 2> "$MERGELIST" || ( clear && echo "You aborted or your search matched too many packages." && exit 1 ) || exit 1 

    clear

    sed -i "s/'//g" $MERGELIST

    emerge -vaD `cat $MERGELIST`

    rm "$MERGELIST"

else
    echo "Your search made no results."
    exit 1
fi
