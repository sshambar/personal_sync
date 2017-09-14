# -*- tab-width: 2; indent-tabs-mode: nil -*- vim:ft=sh:et:sw=2:ts=2:sts=2
# emacs.sh - setup emacs aliases if we have the correct environment

# Requires the following in ~/.emacs (or home-start.el)
#
#;; Start server so shell commands can talk to emacs
#(when (and (fboundp 'server-start)
#	   (not (zerop (length (getenv-internal "MYEC_SERVER_NAME")))))
#  (setq server-name (getenv-internal "MYEC_SERVER_NAME"))
#  (server-start)
#  ;; export socket-dir to shells
#  (if (not server-use-tcp)
#      (setenv "MYEC_SERVER_SOCKDIR" server-socket-dir)))

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

setup_emacs() {

  local myec_version

  if [ `id -ru` != 0 -a -n "$(command -v emacsclient)" ]; then
    myec_version=$(emacsclient -V)
    myec_version=${myec_version##* }
    myec_version=${myec_version%%.*}
    # before version 23:
    #  no -c (create-frame)
    #  -a "" doesn't start daemon,
    #  no -t (current-terminal)
  fi

  if [ -n "$INSIDE_EMACS" ]; then
    # fallback pager
    export PAGER="/bin/cat"
  fi

  if [ -n "$INSIDE_EMACS" -a -n "$MYEC_SERVER_SOCKDIR" ]; then

    MYEC_SERVER_NAME="${MYEC_SERVER_NAME:-server}"
    local myec_server_sock="$MYEC_SERVER_SOCKDIR/$MYEC_SERVER_NAME"

    # check client version vs server
    if [ -n "$myec_version" ]; then
      case "$INSIDE_EMACS" in
        ${myec_version}*) ;;
        *) myec_version= ;;
      esac
    fi

    # shell inside emacs
    if [ -n "$myec_version" -a -S "$myec_server_sock" ]; then

      # we have emacsclient and a running daemon

      # EDITOR should block inside emacs
      export EDITOR="emacsclient -s $myec_server_sock"

      # emacs/less/man should give prompt back inside emacs
      alias emacs="$EDITOR -n"
      alias less="$EDITOR -n"
      alias more="$EDITOR -n"
      # just handle one man entry...
      man() { $EDITOR >/dev/null -n -e "(man \"$1\")"; }

      # use emacsclient-pager if available (handles stdin)
      if [ -n "$(command -v emacsclient-pager)" ]; then
        PAGER="emacsclient-pager"
        if [ -n "$(command -v emacsclient-diff)" ]; then
          export DIFF_PAGER="emacsclient-diff"
        else
          export DIFF_PAGER="$PAGER"
        fi
      fi
    fi

  elif [ -n "$myec_version" ]; then

    # outside emacs, have emacsclient
    local myec_tty=$(tty)
    if [ -n "$myec_tty" ]; then
      # use only the tty filename
      export MYEC_SERVER_NAME=server-${myec_tty##*/}
    fi
  fi
}

setup_emacs
unset -f setup_emacs
