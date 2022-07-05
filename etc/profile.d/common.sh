# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# common.sh - common defines

# Skip all for noninteractive shells.
[ -t 0 ] || return

function scr() {
  local args
  [ -z "$1" ] && args="-d -RR"
  command screen -U $args "$@"
}

# nice shortcuts
alias h=history 2>/dev/null
alias sha256sum='openssl dgst -sha256'

# colors in man pages!
command >/dev/null -v less && export MANPAGER="less -R --use-color -Dd+Y -Du+W"
# enable less to recognize underline/bold (no ascii escapes)
# this only affects pages created on the fly (not catman pages)
export GROFF_NO_SGR=1

# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
