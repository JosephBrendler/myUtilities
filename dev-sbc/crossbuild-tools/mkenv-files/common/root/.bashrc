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

[ -e /root/firstenvlogin ] && /usr/local/sbin/finalize-chroot || echo 'basic chroot already configured'
[ -e /root/firstimglogin ] && /usr/local/sbin/finalize-chroot-for-image || echo 'image chroot already configured'

install_my_local_ca_certificates

machine=$(portageq envvar CHOST | cut -d'-' -f1)

# set prompt after determining if running inside chroot
# by comparing inode of / and /proc/1/root
if [ "$(stat -c %i /)" != "$(stat -c %i /proc/1/root)" ]; then
    echo "Inside chroot"
else
    echo "Not in chroot"
fi

# (above doesn't work yet - change this manually after deployed)
export PS1="(${machine} chroot) ${PS1}"
