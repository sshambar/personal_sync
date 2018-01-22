# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# common.sh - common defines

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

function scr() {
  local args
  [ -z "$1" ] && args="-d -RR"
  command screen -U $args "$@"
}

# nice shortcuts
alias h=history 2>/dev/null

# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
