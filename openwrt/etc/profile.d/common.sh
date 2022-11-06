
# interactive only
[[ $- == *i* ]] || return 0

# no .lesshst file
export LESSHISTFILE=-

# strip leading screen. on TERM
TERM=${TERM#screen.}

scr() {
  local args
  [ -z "$1" ] && args="-d -RR"
  command screen -U $args "$@"
}

