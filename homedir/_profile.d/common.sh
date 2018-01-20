# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# common.sh - common defines

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

function scr() {
  local args
  if [ "$*" == "" ]; then args="-U -R"; else args="-U $*"; fi
  script -q -c "screen $args" /dev/null
}

# nice shortcuts
alias h=history 2>/dev/null

# use dnf cache files if not running as root
if [ "${EUID:-}" != 0 ] ; then
  alias dnf='dnf --cacheonly' 2>/dev/null
fi
# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
