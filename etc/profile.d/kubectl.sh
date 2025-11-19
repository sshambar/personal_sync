# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:
# shellcheck shell=sh disable=SC3044

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

command -v kubectl >/dev/null || return 0

alias kc=kubectl
if [ -n "$BASH" ]; then
  _my_kc_load_comp() {
    declare -F __load_completion >/dev/null || return 0
    __load_completion kubectl && complete -o default -F __start_kubectl kc
  }
  complete -o default -F _my_kc_load_comp kc
fi

kcns() {
  _c=$(kubectl config current-context)
  if [ -n "$_c" ]; then
    if [ -n "$1" ]; then
      kubectl config set "contexts.$_c.namespace" "$1"
    else
      kubectl config view \
              -o jsonpath="{.contexts[?(@.name == \"$_c\")].context.namespace}"
      echo
    fi
  else
    echo >&2 "Unable to find current context"
  fi
  unset _c
}

