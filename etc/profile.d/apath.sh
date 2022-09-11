# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:
#
# apath.sh - path add functions (add zpath.sh for cleanup)

# User specific aliases and functions
remove_path() {
  # <var-name> <directory>
  [[ $1 && $2 ]] || return 0

  local mypath=${!1-}
  [[ $mypath ]] || return 0
  mypath=":$mypath:"

  mypath=${mypath//:$2:/:}
  mypath=${mypath%:}
  printf -v "$1" %s "${mypath#:}"
}

add_path () {
  # <var-name> <directory> [ "before" ]
  [[ $1 && $2 ]] || return 0

  # first, remove directory if present
  remove_path "$1" "$2"

  # only add directories that exist
  [[ -d $2 ]] || return 0

  local mypath=${!1-}
  [[ -z $mypath ]] && { printf -v "$1" %s "$2"; return; }

  if [[ $3 == before ]]; then
    printf -v "$1" %s "$2:$mypath" || return
  else
    printf -v "$1" %s "$mypath:$2" || return
  fi
  return 0
}

add_root_path() {
  # <directory> [ "before" ]
  local j=$1
  [[ -d $j ]] || return 0
  j="${j%%/}/"
  add_path PATH "${j}bin" "$2"
  # skip system library paths
  [[ $LD_LIBRARY_PATH && $j != / && $j != /usr/ ]] &&
     add_path LD_LIBRARY_PATH "${j}lib" "$2"
  add_path MANPATH "${j}share/man" "$2"
  add_path INFOPATH "${j}share/info" "$2"
}

# basic paths
for i in /usr/local /usr /; do add_root_path "$i"; done
