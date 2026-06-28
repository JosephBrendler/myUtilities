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
# Put your fun stuff here

#-----[ my aliases ]------------------------------------------------------------------
alias la='ls -al --color=tty'
alias lr='ls -alrt --color=tty'
alias tl='tail -n50'
#-----[ script "headers" ]------------------------------------------------------------
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_extended
source /usr/sbin/bashrc_aliases_include_joe_brendler

#-----[ consolidate history from all sessions ]---------------------------------------
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it
# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

#-----[ chroot section ]----------------------------------------------------
[ -f ~/.cb-config  ] && source ~/.cb-config   # assigns cb_BOARD, cb_TARGET, cb_TARGET_ARCH, cb_QEMU_ARCH, etc.
#-----[ v-- edit/comment-out BELOW after system deployment --v ]-----------------------
/usr/sbin/install_my_local_ca_certificates
rerunmsg="first-run chroot configuration not requested by presense of marker"
if cat /root/firstlogin 2>/dev/null ; then /usr/sbin/finalize-chroot-sys; else j_msg -5 "$rerunmsg"; fi

echo
j_msg "-${warn}" -p "edit /root/.bashrc after first boot of new system, to modify prompt, etc."
echo
export PS1="(chroot) ${PS1}"
#-----[ ^-- edit/comment-out ABOVE after system deployment --^ ]-----------------------

#-----[ XDG_RUNTIME_DIR ]--------------------------------------------------------------
# moved to .bash_profile

#-----[ GPG_TTY ]-----------------------------------------------------------------------
# export GPG_TTY so gpg-agent will work (to sign commits)
export GPG_TTY=$(tty)

#-----[ neofetch ]----------------------------------------------------------------------
command -v neofetch &>/dev/null && { echo ; neofetch ; echo ; }
# output info on GPG, XDG, cb_ environment variables
env | grep -E 'GPG|XDG|cb_'
