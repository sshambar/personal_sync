# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# server.sh - server specific defines

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

# nice shortcuts
alias sc=systemctl
alias jc=journalctl

[ -n "$(declare -F pathmunge)" -a -d ~/.bin ] && pathmunge ~/.bin

# use dnf cache files if not running as root
if [ "${EUID:-}" != 0 ] ; then
  alias dnf='dnf --cacheonly' 2>/dev/null
fi
# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
