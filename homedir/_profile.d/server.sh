# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# server.sh - server specific defines

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

[ -n "$(declare -F pathmunge)" ] && {
  [ -d ~/.bin ] && pathmunge ~/.bin
  [ -d ~/.local/bin ] && pathmunge ~/.local/bin
}

if [ "${EUID:-}" != 0 ] ; then
  alias sc='systemctl --user'
  alias jc='journalctl --user'
  # use dnf cache files if not running as root
  alias dnf='dnf --cacheonly' 2>/dev/null
else
  alias sc=systemctl
  alias jc=journalctl

  asuser() { # <uid> <cmd>...
    [ -z "$1" ] && echo "Usage: asuser <user> [ <cmd>... ]" && return 1
    local uid=$(id 2>/dev/null -ru "$1") gid=$(id 2>/dev/null -rg "$1")
    [ -z "$uid" -o -z "$gid" ] && echo "Invalid user '$1'" && return 2
    shift
    [ -z "$1" ] && set bash
    setpriv --reset-env --no-new-privs --reuid=$uid --regid=$gid --init-groups env XDG_RUNTIME_DIR=/run/user/$uid "$@"
  }

  scu() { # <uid> [<cmd>]...
    [ -z "$1" ] && echo "Usage: scu <user> [ <sc arg> ]" && return 1
    local user=$1; shift
    asuser "$user" systemctl --user "$@"
  }
fi

# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
