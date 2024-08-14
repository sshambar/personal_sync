# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:
#
# emacs.sh v1.1 - setup emacs aliases if we have the correct environment
#
# Requires the following in ~/.emacs (or home-start.el)
#
#;; Start server so shell commands can talk to emacs
#(when (and (fboundp 'server-start)
#	   (not (zerop (length (getenv-internal "MYEC_SERVER_NAME")))))
#  (setq server-name (getenv-internal "MYEC_SERVER_NAME"))
#  (server-start)

# Skip all for noninteractive shells.
[[ -t 0 ]] || return 0

setup_emacs() {

  command -v emacs &>/dev/null || return 0

  export EDITOR=${EDITOR:-emacs}

  command -v ediff &>/dev/null && export MERGE=${MERGE:-ediff}

  # fallback pager
  [[ $INSIDE_EMACS ]] && export PAGER=cat

  command -v emacsclient &>/dev/null || return 0

  # shell inside emacs, and server alive...
  if [[ $INSIDE_EMACS ]] &&
       emacsclient -s "$MYEC_SERVER_NAME" -e t &>/dev/null; then
    local s
    # try to use full socket path so EDITOR works in "sanitized" environments
    s=$(emacsclient -s "$MYEC_SERVER_NAME" -e "(eval 'server-socket-dir)")
    s=${s#\"}; s=${s%\"}; s="$s/$MYEC_SERVER_NAME"
    [[ -S $s ]] || s=$MYEC_SERVER_NAME
    # EDITOR should block inside emacs
    export EDITOR="emacsclient -s \"$s\""
    # remove VISUAL, it may mask EDITOR
    unset VISUAL

    # emacs/less/man should give prompt back inside emacs
    alias emacs="$EDITOR -n"
    alias vi="$EDITOR -n"
    alias less="$EDITOR -n"
    alias more="$EDITOR -n"
    # just handle one man entry...
    man() { $EDITOR >/dev/null -n -e "(man \"$1\")"; }

    # use emacsclient-pager if available (handles stdin)
    if command -v emacsclient-pager &>/dev/null; then
      # MYEC_TTY is used to get current rows
      export MYEC_TTY=$(tty)
      PAGER="emacsclient-pager"
      alias less="$PAGER"
      alias more="$PAGER"
      if command -v emacsclient-diff &>/dev/null; then
        export DIFF_PAGER="emacsclient-diff"
        alias diff="$DIFF_PAGER"
      else
        export DIFF_PAGER=$PAGER
      fi
    fi

  else

    # outside emacs, have emacsclient
    local myec_tty=$(tty)
    # use only the tty filename
    [[ $myec_tty ]] && export MYEC_SERVER_NAME="server-${myec_tty##*/}"
  fi
}

setup_emacs
unset -f setup_emacs
