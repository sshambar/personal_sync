# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# mac.sh - local defines for OSX

# utf8 baby
export LANG=en_US.UTF-8

# macports....
add_root_path /opt/local/ before

# Rest for interactive terminals only
[[ -t 0 ]] || return

# developer bin
add_path PATH /Applications/Xcode.app/Contents/Developer/usr/bin
add_path PATH /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin

# local sbin (for sudo)
add_path PATH /sbin
add_path PATH /usr/sbin
add_path PATH /usr/local/sbin
add_path PATH /opt/local/sbin

# order these early
add_path PATH /usr/local/bin before
add_path PATH ~/.bin before

# developer man pages
[[ $MANPATH ]] && {
  add_path MANPATH /Applications/Xcode.app/Contents/Developer/usr/share/man
  add_path MANPATH /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man
}

# macports emacs
[[ $INFOPATH ]] && add_path INFOPATH /opt/local/share/info/emacs before

# macports devel directories
#if [ -d /opt/local/lib ]; then
#  add_path PKG_CONFIG_PATH "/opt/local/lib/pkgconfig"
#  add_path ACLOCAL_PATH "/opt/local/share/aclocal"
#fi

[[ $PKG_CONFIG_PATH ]] && export PKG_CONFIG_PATH
[[ $ACLOCAL_PATH ]] && export ACLOCAL_PATH

# nice shortcuts
plshow() { plutil -convert xml1 -o - "$@"; }

# ls with forest and color
alias ll='ls -l'

# OSX has different tools
strace() { echo "use dtruss or dtrace"; }
ldd() { objdump -macho -dylibs-used -non-verbose "$@"; }

alias dialout='screen /dev/cu.SLAB_USBtoUART 115200'

case $TERM in
  xterm*|screen*)
    export CLICOLOR=1
    export LSCOLORS=gxfxbeaebxxehehbadacad
    # because screen breaks apps
    #unset TERMCAP
    ;;
esac

if [[ $SSH_AUTH_SOCK ]]; then
  # use MacOS's ssh-add to auto-spawn ssh-agent (and use keychain passphrase)
  [ $(/usr/bin/ssh-add -l | grep -v ^The | wc -l) -ne 0 ] || {
    echo "Adding keys to ssh-agent..."
    /usr/bin/ssh-add --apple-load-keychain
  }
fi

shopt -s extglob histappend

# mac classic less doesn't support color correctly
[[ $MANPAGER && $(command -v less) == /usr/bin/less ]] && unset MANPAGER

# don't annoy us...
export BASH_SILENCE_DEPRECATION_WARNING=1

# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
