# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:
#
# title.sh - titles on capable terminals (bash)

# Skip all for noninteractive shells.
[[ -t 0 ]] || return 0

mysetprompt() {
  case $TERM in
    xterm*|screen*)
      local pkey="]2;" home="\\~"
      # on screen, use title (set hardstatus to use %t so can format it)
      [[ $TERM =~ ^screen ]] && pkey="k"
      (( ${BASH_VERSINFO[0]} < 4 )) && home="~"
      PROMPT_COMMAND="[[ ! -t 1 ]] || printf '\033${pkey}%s\033\\' "'"$USER@${HOSTNAME%%.*}:${PWD/#$HOME/'"$home"'}"'
      telnet() { [[ -t 1 ]] && { local _x=${PROMPT_COMMAND#* \'}; printf "${_x%%\' *}" "telnet $*"; }; command telnet "$@"; }
      ssh() { [[ -t 1 ]] && { local _x=${PROMPT_COMMAND#* \'}; printf "${_x%%\' *}" "ssh $*"; }; command ssh "$@"; }
      ;;
  esac
  return 0
}

if [[ $BASH_VERSION ]]; then
  PS1="[\u@\h \W]\\$ "
  mysetprompt
else
  PS1="[$USER@\\h \\W]\\$ "
fi
unset -f mysetprompt
