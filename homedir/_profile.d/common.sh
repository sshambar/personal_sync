# -*- tab-width: 2; indent-tabs-mode: nil -*- vim:ft=sh:et:sw=2:ts=2:sts=2
# common.sh - common defines

# Skip all for noninteractive shells.
[ ! -t 0 ] && return

function scr() {
  local args
  if [ "$*" == "" ]; then args="-U -R"; else args="-U $*"; fi
  script -q -c "screen $args" /dev/null
}

# nice shortcuts
alias h=history

