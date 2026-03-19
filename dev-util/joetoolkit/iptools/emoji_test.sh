#!/bin/bash
#
#   edit with ' LC_ALL=en_US.utf8 nano emoji_test.sh '   to actually see the emoji in the editor
#
# Define emoji and a fallback text for TTY
EMOJI="✨"
TEXT_FALLBACK="[OK]"

if [[ $(tput colors) -ge 256 ]]; then
  # This branch runs on a graphical terminal that supports color
  echo "Task complete ${EMOJI}"
else
  # This branch runs on the TTY or a terminal with limited capabilities
  echo "Task complete ${TEXT_FALLBACK}"
fi

