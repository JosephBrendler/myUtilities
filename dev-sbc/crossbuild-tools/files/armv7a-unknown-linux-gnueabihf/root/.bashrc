# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !


# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
        # Shell is non-interactive.  Be done now!
        return
fi


# Put your fun stuff here.

alias la='ls -al --color=tty'
alias lr='ls -alrt --color=tty'

source /usr/local/sbin/script_header_brendlefly
source /usr/local/sbin/script_header_brendlefly_extended
source /usr/local/sbin/bashrc_aliases_include_joe_brendler

source /etc/bash/bashrc.d/emerge-chroot

export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it

# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

export PS1="(armv7a chroot) $PS1"
[ -e /root/firstlogin ] && /usr/local/sbin/finalize-chroot || echo 'chroot already configured'
install_my_local_ca_certificates
