# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# title.sh - titles on capable terminals (bash)

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

if [ -n "$BASH_VERSION" ]; then
  PS1="[\u@\h \W]\\$ "
  # on screen, use title (set hardstatus to use %t so can format it)
  [[ "$TERM" =~ ^screen ]] && pfmt='printf "\033k%s\033\\"' || \
      pfmt='printf "\033]2;%s\033\\"'
  case $TERM in
    xterm*|screen*)
      if [[ "$BASH_VERSION" =~ ^3. ]]; then
        PROMPT_COMMAND="$pfmt"' "$USER@${HOSTNAME%%.*}:${PWD/#$HOME/~}"'
      else
        PROMPT_COMMAND="$pfmt"' "$USER@${HOSTNAME%%.*}:${PWD/#$HOME/\~}"'
      fi
      eval 'telnet() { '"$pfmt"' "telnet $*"; command telnet "$@"; }'
      eval 'ssh() { '"$pfmt"' "ssh $*"; command ssh "$@"; }'
      ;;
    *)
      ;;
  esac
  unset pfmt
else
  PS1="[$USER@\\h \\W]\\$ "
fi

# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
