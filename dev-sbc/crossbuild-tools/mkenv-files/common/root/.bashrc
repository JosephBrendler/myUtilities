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
source /root/.cb-config   # assigns BOARD, TARGET, TARGET_ARCH, QEMU_ARCH

export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it

# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

rerunmsg="first-run chroot configuration not requested by presense of marker"
[ -e /root/firstenvlogin ] && /usr/local/sbin/finalize-chroot || \
    echo -e "${rerunmsg} /root/firstenvlogin;\nre-run if needed with /usr/local/sbin/finalize-chroot"
[ -e /root/firstimglogin ] && /usr/local/sbin/finalize-chroot-for-image || \
    echo -e "${rerunmsg} /root/firstimglogin;\nre-run if needed with /usr/local/sbin/finalize-chroot-for-image"

install_my_local_ca_certificates

echo
E_message "edit /root/.bashrc after first boot of real image, to modify prompt, etc."
echo

export PS1="(${QEMU_ARCH} chroot) ${PS1}"

