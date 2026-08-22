# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:
#
# homebrew.sh v1.1 - defines used with homebrew install

[[ -t 0 ]] || return 0

if [[ -d /opt/homebrew/Cellar ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
elif [[ -d /usr/local/Cellar ]]; then
  export HOMEBREW_PREFIX=/usr/local
fi
[[ ${HOMEBREW_PREFIX-} ]] || return 0

add_root_path "$HOMEBREW_PREFIX" before

[[ ${BASH_VERSION-} ]] && {
  [[ -r $HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh ]] &&
    . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
}

# homebrew devel directories
add_path PKG_CONFIG_PATH "$HOMEBREW_PREFIX/lib/pkgconfig"
export PKG_CONFIG_PATH
add_path ACLOCAL_PATH "$HOMEBREW_PREFIX/share/aclocal"
export ACLOCAL_PATH
