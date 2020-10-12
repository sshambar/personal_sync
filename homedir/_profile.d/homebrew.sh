[ ! -t 0 ] && return

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
add_path ACLOCAL_PATH "${HOMEBREW_PREFIX}/share/aclocal"


