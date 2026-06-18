# /etc/skel/.bash_profile

# This file is sourced by bash for login shells.

#-----[ XDG_RUNTIME_DIR ]--------------------------------------------------------------
# gentoo news instructed to do this, but investigation shows it is ignored
#export XDG_RUNTIME_DIR=/tmp/xdg/$USER
#if test -z "${XDG_RUNTIME_DIR}"; then
#  export XDG_RUNTIME_DIR=/tmp/xdg/"${UID}"-xdg-runtime-dir
#    if ! test -d "${XDG_RUNTIME_DIR}"; then
#        mkdir -p "${XDG_RUNTIME_DIR}"
#        chmod 0700 "${XDG_RUNTIME_DIR}"
#    fi
#fi
#
# define XDG Base Directories conforming to standard expectations
if test -z "${XDG_RUNTIME_DIR}"; then
    # strategy 1 - check for pre-existing standard elogind managed path
    if test -d "/run/user/${UID}"; then
        export XDG_RUNTIME_DIR="/run/user/${UID}"
    else
        # strategy 2 - fallback to create an in-memory tmpfs space
        # (make this consistent with elogind norm, if possible)
        # /run/user is preferred; /dev/shm is a flawless alternative
        if test -d "/run" && touch "/run/.writable_test" 2>/dev/null; then
            rm "/run/.writable_test"
            _xdg_base="/run/user"
        else
            _xdg_base="/dev/shm/user"
        fi
        export XDG_RUNTIME_DIR="${_xdg_base}/${UID}-runtime"
        if ! test -d "${XDG_RUNTIME_DIR}"; then
            mkdir -p "${XDG_RUNTIME_DIR}"
            chmod 0700 "${XDG_RUNTIME_DIR}"
        fi
        unset -v _xdg_base
    fi
fi

#The following line runs your .bashrc and is recommended by the bash info pages
if [[ -f ~/.bashrc ]] ; then
  . ~/.bashrc
fi
