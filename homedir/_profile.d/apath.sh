# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# apath.sh - path add functions (add zpath.sh for cleanup)

# User specific aliases and functions
remove_path() {
  # <var-name> <directory>
  [ -n "$1" -a -n "$2" ] || return

  local mypath
  eval mypath=\$`echo $1`
  [ -z "$mypath" ] && return
  mypath=:$mypath:

  mypath=${mypath//:$2:/:}
  mypath=${mypath%:}
  eval $1=${mypath#:}
}

add_path () {
  # <var-name> <directory> [ "before" ]
  [ -n "$1" -a -n "$2" ] || return

  # first, remove directory if present
  remove_path "$1" "$2"

  # only add directories that exist
  [ -d "$2" ] || return

  local mypath
  eval mypath=\$`echo $1`
  [ -z "$mypath" ] && eval $1=$2 && return

  [ "$3" = "before" ] && eval $1=$2:$mypath || eval $1=$mypath:$2
}

add_root_path() {
  # <directory> [ "before" ]
  local j=$1
  [ ! -d "$j" ] && return
  [ "${j%/}" = "$j" ] && j="$j/"
  add_path PATH "${j}bin" "$2"
  # skip system library paths
  [ "$j" = / -o "$j" = /usr/ ] || add_path LD_LIBRARY_PATH "${j}lib" "$2"
  add_path MANPATH "${j}share/man" "$2"
  add_path INFOPATH "${j}share/info" "$2"
}

# we're setting these, export them
export PATH LD_LIBRARY_PATH MANPATH INFOPATH

# basic paths
for i in /usr/local /usr /; do add_root_path $i; done

# cleanup
[ -z "$LD_LIBRARY_PATH" ] && unset LD_LIBRARY_PATH
[ -z "$MANPATH" ] && unset MANPATH
[ -z "$INFOPATH" ] && unset INFOPATH

# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
