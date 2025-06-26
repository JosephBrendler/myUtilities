#!/bin/bash
  
FOLDER="$HOME/screenshots/"
  
if [ ! -d "${FOLDER}" ]; then
  mkdir ${FOLDER}
fi
  
DATE=$(date +%Y-%m-%d@%H.%M.%S)
FNAME="${FOLDER}screenshot-${DATE}.png"
C=0
while [ -f "${FNAME}" ] ; do
    FNAME="${FOLDER}screenshot-${DATE}.${C}.png"
    let C++
done
  
touch ${FNAME}
  
if [ "$1" != "window" ]; then
  if xwd -root | convert - "${FNAME}"; then
    notify-send "Desktop screenshot saved!" "Desktop screenshot was saved as:\n ${FNAME}"
  else
    notify-send "Desktop screenshot could not be saved!" "There was an error."
  fi
else
  if xwd | convert - "${FNAME}"; then
    notify-send "Window screenshot saved!" "Window screenshot was saved as:\n ${FNAME}"
  else
    notify-send "Window screenshot could not be saved!" "There was an error."
  fi
fi

