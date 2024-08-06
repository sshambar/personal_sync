# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:
#
# server.sh v1.0 - linux server specific defines

# Skip all for noninteractive shells.
[[ -t 0 ]] || return 0

declare >/dev/null -F pathmunge && {
  [[ -d ~/.bin ]] && pathmunge ~/.bin
  [[ -d ~/.local/bin ]] && pathmunge ~/.local/bin
}

if [[ ${EUID-} != 0 ]] ; then
  [[ -z $XDG_RUNTIME_DIR && -d /run/user/$EUID ]] && \
    export XDG_RUNTIME_DIR="/run/user/$EUID"
  alias sc='systemctl --user'
  alias jc='journalctl --user'
  # use dnf cache files if not running as root
  alias dnf='dnf --cacheonly' 2>/dev/null
else
  alias sc=systemctl
  alias jc=journalctl

  asuser() { # <uid> <cmd>...
    [[ $1 ]] || { echo "Usage: asuser <user> [ <cmd>... ]"; return 1; }
    local uid=$(id 2>/dev/null -ru "$1") gid=$(id 2>/dev/null -rg "$1")
    [[ $uid && $gid ]] || { echo "Invalid user '$1'"; return 2; }
    shift
    [[ $1 ]] || set bash
    setpriv --reset-env --reuid=$uid --regid=$gid \
            --init-groups env XDG_RUNTIME_DIR="/run/user/$uid" "$@"
  }

  scu() { # <uid> [<cmd>]...
    [[ $1 ]] || { echo "Usage: scu <user> [ <sc arg> ]"; return 1; }
    local user=$1; shift
    asuser "$user" systemctl --user "$@"
  }
fi

[[ $INSIDE_EMACS ]] && export SYSTEMD_PAGER=
