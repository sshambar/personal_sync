# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# title.sh - titles on capable terminals (bash)

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

# for interactive terminals only
setup_title() {

  case $TERM in
    xterm*|screen*)
      if [[ "$BASH_VERSION" =~ ^3. ]]; then
        PROMPT_COMMAND='printf "\033]2;%s@%s:%s\033\\" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
      else
        PROMPT_COMMAND='printf "\033]2;%s@%s:%s\033\\" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
      fi
      telnet() { printf "\033]2;%s\033\\" "telnet $*"; command telnet "$@"; }
      ssh() { printf "\033]2;%s\033\\" "ssh $*"; command ssh "$@"; }
      ;;
    *)
      ;;
  esac
}

if [ -n "$BASH_VERSION" ]; then
  PS1="[\u@\h \W]\\$ "
  setup_title
else
  PS1="[$USER@\\h \\W]\\$ "
fi

unset -f setup_title
# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
