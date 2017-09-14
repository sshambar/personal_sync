# -*- tab-width: 2; indent-tabs-mode: nil -*- vim:ft=sh:et:sw=2:ts=2:sts=2
# title.sh - titles on capable terminals (bash)

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
      reset_title() { xtitle "${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}"; }
      PROMPT_COMMAND="reset_title"
      wrap_cmd() { xtitle $1; command "$@"; }
      telnet() { wrap_cmd $FUNCNAME "$@"; }
      ssh() { wrap_cmd $FUNCNAME "$@"; }
      ;;
    *)
      ;;
  esac
}

if [ -n "$PS1" ]; then
  if [ -n "$BASH_VERSION" ]; then
    PS1="[\\u@\\h \\W]\\$ "
    setup_title
  else
    PS1="[$USER@\\h \\W]\\$ "
  fi
fi
