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

#-----[ keychain ]--------------------------------------------------------------------
# start keychain and point it at private keys to be cached
#/usr/bin/keychain ~/.ssh/id_rsa
#/usr/bin/keychain ~/.ssh/id_ecdsa
#/usr/bin/keychain ~/.ssh/id_ed25519
# source environment variables from <hostname>-sh
#source ~/.keychain/g5nuc01-sh > /dev/null

#-----[ ssh-agent ]-------------------------------------------------------------------
### ssh-agent/-add (if not already loaded) instead of keychain
#sshkey_rsa="/home/joe/.ssh/id_rsa"
#sshkey_ecdsa="/home/joe/.ssh/id_ecdsa"
#sshkey_ed25519="/home/joe/.ssh/id_ed25519"
## set SSH_AUTH_SOCK env var to a fixed value
#export SSH_AUTH_SOCK="/home/joe/.ssh/ssh-agent.sock"
## test whether ${SSH_AUTH_SOCK} is valid
#ssh-add -l 2>/dev/null >/dev/null
## if not valid,  remove the old one, then start ssh-agent using ${SSH_AUTH_SOCK}
#[ $? -ge 2 ] && ( rm ${SSH_AUTH_SOCK}; ssh-agent -a ${SSH_AUTH_SOCK} >/dev/null )
## check for ssh keys, and add if they are not already loaded
#[[ -z $(ssh-add -l | grep -v "no identities") ]] && \
#  for x in ${sshkey_rsa} ${sshkey_ecdsa} ${sshkey_ed25519}; do ssh-add ${x}; done

#-----[ my aliases ]------------------------------------------------------------------
alias la='ls -al --color=tty'
alias lr='ls -alrt --color=tty'
alias tl='tail -n50'

#-----[ script "headers" ]------------------------------------------------------------
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_extended
source /usr/sbin/script_header_joetoo_unicode
source /usr/sbin/bashrc_aliases_include_joe_brendler

#-----[ consolidate history from all sessions ]---------------------------------------
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it
# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

#-----[ crossbuild chroot section ]----------------------------------------------------
source /root/.cb-config   # assigns cb_BOARD, cb_TARGET, cb_TARGET_ARCH, cb_QEMU_ARCH, etc.
#-----[ v-- edit/comment-out BELOW after system deployment --v ]-----------------------
#install_my_local_ca_certificates
#source /etc/bash/bashrc.d/emerge-chroot
#rerunmsg="first-run chroot configuration not requested by presense of marker"
#if [ -e /root/firstenvlogin ] ; then
#    /usr/sbin/finalize-chroot
#else
#    echo -e "${rerunmsg} /root/firstenvlogin;\nre-run if needed with /usr/sbin/finalize-chroot"
#fi
#if [ -e /root/firstimglogin ] ; then
#    /usr/sbin/finalize-chroot-for-image
#else
#    echo -e "${rerunmsg} /root/firstimglogin;\nre-run if needed with /usr/sbin/finalize-chroot-for-image"
#fi
#if [ -e /root/firstupdatelogin ] ; then
#    /usr/sbin/finalize-chroot-for-update
#else
#    echo -e "${rerunmsg} /root/firstimglogin;\nre-run if needed with /usr/sbin/finalize-chroot-for-image"
#fi
#echo
#E_message "edit /root/.bashrc after first boot of real image, to modify prompt, etc."
#echo
#export PS1="(${cb_QEMU_ARCH} chroot) ${PS1}"
#-----[ ^-- edit/comment-out ABOVE after system deployment --^ ]-----------------------

#-----[ XDG_RUNTIME_DIR ]--------------------------------------------------------------
# gentoo news instructed to do this, but investigation shows it is ignored
#export XDG_RUNTIME_DIR=/tmp/xdg/$USER
if test -z "${XDG_RUNTIME_DIR}"; then
  export XDG_RUNTIME_DIR=/tmp/xdg/"${UID}"-xdg-runtime-dir
    if ! test -d "${XDG_RUNTIME_DIR}"; then
        mkdir -p "${XDG_RUNTIME_DIR}"
        chmod 0700 "${XDG_RUNTIME_DIR}"
    fi
fi

#-----[ GPG_TTY ]-----------------------------------------------------------------------
# export GPG_TTY so gpg-agent will work (to sign commits)
export GPG_TTY=$(tty)

#-----[ neofetch ]----------------------------------------------------------------------
echo
neofetch
echo
