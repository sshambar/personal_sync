# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:
#
# common.sh v1.0 - common defines

# Skip all for noninteractive shells.
[[ -t 0 ]] || return 0

function scr() {
  local args
  [[ $1 ]] || args="-d -RR"
  command screen -U $args "$@"
}

# nice shortcuts
alias h=history
command -v openssl >/dev/null && {
  command -v sha256sum >/dev/null || alias sha256sum='openssl dgst -sha256'; }

# colors in man pages!
command >/dev/null -v less && export MANPAGER="less -R --use-color -Dd+G -Du+R"
# enable less to recognize underline/bold (no ascii escapes)
# this only affects pages created on the fly (not catman pages)
export GROFF_NO_SGR=1

[[ $TERM =~ ^xterm.*256color.* ]] && { COLORTERM=24bit; }
