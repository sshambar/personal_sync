#!/usr/bin/env bash
# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
#
# find-diffs v1.0 - Finds candidates for adding to /etc/sysupgrade.conf
# Author: Scott Shambarger <devel@shambarger.net>
#
# Copyright (C) 2018 Scott Shambarger
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Finds all changed files in /overlay/upper compared to /rom
# Excludes anything in /lib/upgrade/keep.d or /etc/sysupgrade.conf
#   and any files in upgraded packages.
# Also excludes /usr/lib/opkg...
#

debug=0
show_new=1
mode=files

usage() {
  echo "Find candidates for /etc/sysupgrade.conf"
  echo "Usage: [ -d ] [ -r | -o ]"
  echo " -d - enable debug output (repeat for more)"
  echo " -r - only include files in /rom (no new files)"
  echo " -o - show opkg installation differences"
  exit 1
}

while :; do
  case "$1" in
    -d|--debug) ((debug++)); shift;;
    -o|--opkg) mode=opkg; shift;;
    -r|--rom) show_new=; shift;;
    -*) usage;;
    *) break;;
  esac
done

#
# LOGGING FUNCTIONS
#

err() {
  local IFS=' '; echo 1>&2 "$*"
}

# backtrace to stderr, skipping <level> callers
backtrace() { # <level>
  local -i x=$1; echo 1>&2 "Backtrace: <line#> <func> <file>"
  while :; do ((x++)); caller 1>&2 $x || return 0; done
}

# print <msg> to stderr, and dump backtrace of callers
fatal() { # <msg>
  local IFS=' '; printf 1>&2 "FATAL: %s\n" "$*"
  exit 1
}

# fd for debug/verbose output
exec 3>&1

xdebug() { # <msg>
  local IFS=' '
  printf 1>&3 "%16s: %s\n" "${FUNCNAME[2]}" "${*//$'\a'/\\}"
  return 0
}

[ $debug -gt 0 ] && debug() { xdebug "$@"; } || debug() { :; }
[ $debug -gt 1 ] && debug2() { xdebug "$@"; } || debug2() { :; }
[ $debug -gt 2 ] && debug3() { xdebug "$@"; } || debug3() { :; }

verbose() {
  [[ $verbose ]] || return
  local IFS=' '; echo 1>&3 "$*"
}

#
# DATASTORE INTERNAL FUNCTIONS
#

# INTERNAL: declare global DS if it's not an assoc array in scope
_ds_init() {
  [ -n "$BASH_VERSINFO" -a "${BASH_VERSINFO[0]}" -ge 4 ] || \
    fatal "Bash v4 or higher required"
  local v=$(declare 2>/dev/null -p -A DS)
  if [ -z "$v" -o "${v#declare -A DS}" != "$v" ]; then
    # we can declare global DS in bash 4.2+"
    [ "${BASH_VERSINFO[1]}" -ge 2 ] || \
      fatal "'declare -A DS' must be declared before using datastore!"
    debug3 "Initializing DS"
    declare -gA DS
  fi
  unset -f _ds_init
  _ds_init() { :; }
}

# INTERNAL: sets name=\a<i>\a<i2>...\a<in>
_ds_name() { # <n> <i1>...<in> ...(ignored)...
  local IFS=$'\a'; local -i n=$1; name=$'\a'${*:2:$n}
}

# INTERNAL: safely assign <var>=<value>
_ds_ret() { # <var> <value>
  [[ $1 ]] && unset 2>/dev/null -v "$1" && eval $1=\$2
  [[ $2 ]]
}

#
# DS USER FUNCTIONS
#
# optionally "declare -A DS" in local scope before using...
#

# DS[_ds_name($@)]=<value>...
ds_nset() { # <n> [ <key1>...<keyn> ] [ <value>... ]
  _ds_init
  local name value IFS=' '
  _ds_name "$@"; shift $1; value=${*:2}
  debug3 "$name=$value"
  [[ $value ]] || return
  [[ ${DS[_$name]} ]] && DS[_$name]=$value && return
  iname=${name%$'\a'*}
  local -i i=${DS[i$iname]}
  DS[k$iname$'\a'$i]=${name##*$'\a'}; ((i++))
  DS[i$iname]=$i
  DS[_$name]=$value
}

# short for ds_nset(1 <key> <value>...)
ds_set() { # <key> <value>...
  [[ $1 ]] && ds_nset 1 "$@" || ds_nset 0 "${@:2}"
}

# <ret>=value identified by <key1>...<keyn> (true if value)
ds_nget() { # <ret> <n> <key1>...<keyn>
  local name
  _ds_name "${@:2}"
  debug3 "$name => ${DS[_$name]}"
  _ds_ret "$1" "${DS[_$name]}"
}

# short for ds_nget(<ret> 1 <key>) (true if value)
ds_get() { # <ret> <key>
  [[ $2 ]] && ds_nget "$1" 1 "$2" || ds_nget "$1"
}

# <ret>=<i>th key below <key1>...<keyn> (true if value)
ds_ngeti() { # <ret> <n> <key1>...<keyn> <i>
  local name key value
  local -i i=$2
  ((i+=3)); i=${@:$i:1}
  [ $i -lt 0 ] && { _ds_ret "$1"; return; }
  _ds_name "${@:2}"
  key=${DS[k$name$'\a'$i]}
  debug3 "$name#$i => $key"
  _ds_ret "$1" "$key"
}

shopt -s extglob
strip() { # <var> <text>
  debug3 "$@"
  local val=${@:2}
  val=${val##*([[:space:]])}; val=${val%%*([[:space:]])}
  unset 2>/dev/null -v "$1" && eval $1=\$val
}

[ -d /rom/etc ] || fatal "No /rom mount?"
[ -d /overlay/upper ] || fatal "No /overlay mount?"

add_ignore() { # <file>
  local line IFS=' '
  debug "reading ignore file $1"
  while read line; do
    strip line "$line"
    [ -z "$line" ] && continue
    [[ "$line" =~ ^# ]] && continue
    debug2 "ignoring ${line}"
    ds_nset 2 ipat "${line}" 1
  done < "$1"
}

find_ignore() {
  local file line
  for file in $(find /lib/upgrade/keep.d -type f); do
    add_ignore "$file"
  done
  [ -f "/etc/sysupgrade.conf" ] && add_ignore "/etc/sysupgrade.conf"
}

is_ignored() { # <file>
  local -i i=0
  local if tf=$1
  ds_nget "" 2 ifile "$tf" && debug2 "ignored by $tf" && return
  while :; do
    ds_ngeti if 1 ipat $i || break
    ((i++))
    [[ "$tf" =~ $if.* ]] && debug2 "ignored by $if*" && return
  done
  return 1
}

find_diffs() {
  command -v diff >/dev/null || fatal "Where is diff?"
  local file f romf diff IFS=' '

  while read file; do
    f=${file#/overlay/upper}
    [ "$f" = /usr/lib/opkg ] && continue
    romf=/rom$f
    debug2 "checking $f"
    if [ -f "$romf" ]; then
      diff -w -q "$file" "$romf" >/dev/null || continue
      is_ignored "$f" && continue
      debug2 "file $f changed"
    else
      [[ $show_new ]] || continue
      is_ignored "$f" && continue
      debug2 "file $f is new"
    fi
    echo "$f"
  done <<< $(find /overlay/upper -path /overlay/upper/usr/lib/opkg -prune -o -type f)
}

find_opkg() {
  command -v opkg >/dev/null || fatal "Where is opkg?"
  opkg >/dev/null list-installed || fatal "opkg failed"
  opkg >/dev/null -o /rom list-installed || fatal "opkg on /rom failed"
  local line pkg IFS=' '

  while read line; do
    debug2 "orig: $line"
    ds_nset 2 pkg "$line" 1
  done <<< $(opkg -o /rom list-installed)
  while read line; do
    debug2 "inst: $line"
    ds_nget "" 2 pkg "$line" && continue
    verbose "$line"
    [ "$mode" = opkg ] && continue
    pkg=${line%% *}
    debug "ignoring files in package $pkg"
    while read line; do
      [[ "$line" =~ Package.* ]] && continue
      debug2 "ignoring $line"
      ds_nset 2 ifile "$line" 1
    done <<< $(opkg files "$pkg")
  done <<< $(opkg list-installed)
}

case "$mode" in
  files)
    find_ignore
    find_opkg
    find_diffs
    ;;
  opkg)
    verbose=1
    find_opkg
    ;;
esac

