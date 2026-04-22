# /etc/skel/.bash_profile

# This file is sourced by bash for login shells.

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

#The following line
# runs your .bashrc and is recommended by the bash info pages.
if [[ -f ~/.bashrc ]] ; then
  . ~/.bashrc
fi
