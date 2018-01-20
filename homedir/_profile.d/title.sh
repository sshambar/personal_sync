# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# title.sh - titles on capable terminals (bash)

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

# for interactive terminals only
setup_title() {

  case $TERM in
    xterm*)
      xtitle() { echo -n "]2;$*"; }
      ;;
    screen*)
      xtitle() { echo -n "]2;($*)\\"; }
      ;;
    *)
      ;;
  esac

  case $TERM in
    xterm*|screen*)
      if [[ "$BASH_VERSION" =~ ^4. ]]; then
        reset_title() { xtitle "${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}"; }
      else
        reset_title() { xtitle "${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}"; }
      fi
      PROMPT_COMMAND="reset_title"
      wrap_cmd() { xtitle $1; command "$@"; }
      telnet() { wrap_cmd $FUNCNAME "$@"; }
      ssh() { wrap_cmd $FUNCNAME "$@"; }
      ;;
    *)
      ;;
  esac
}

if [ -n "$BASH_VERSION" ]; then
  PS1="[\\u@\\h \\W]\\$ "
  setup_title
else
  PS1="[$USER@\\h \\W]\\$ "
fi

unset -f setup_title
# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
