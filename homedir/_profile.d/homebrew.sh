# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:

[[ -t 0 ]] || return 0

export HOMEBREW_PREFIX=/usr/local
export HOMEBREW_CELLAR="/usr/local/Cellar";
export HOMEBREW_REPOSITORY="/usr/local/Homebrew";
if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
  source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
else
  for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
    [[ -r "$COMPLETION" ]] && source "$COMPLETION"
  done
fi

# homebrew devel directories
add_path PKG_CONFIG_PATH "${HOMEBREW_PREFIX}/lib/pkgconfig"
export PKG_CONFIG_PATH
add_path ACLOCAL_PATH "${HOMEBREW_PREFIX}/share/aclocal"
export ACLOCAL_PATH

export DOCKER_HOST='unix:///Users/scott/.local/share/containers/podman/machine/podman-machine-default/podman.sock'
