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
alias sha256sum='openssl dgst -sha256'

# colorize man pages
export LESS_TERMCAP_mb=$'\E[1;32m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;32m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;4;31m'   # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
export GROFF_NO_SGR=1                  # for konsole and gnome-terminal

# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
