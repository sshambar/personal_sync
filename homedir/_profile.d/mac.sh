# -*- mode:sh; sh-indentation:2 -*- vim:set ft=sh et sw=2 ts=2:
# mac.sh - local defines for OSX

# utf8 baby
export LANG=en_US.UTF-8

# macports....
add_root_path /opt/local/ before

# Rest for interactive terminals only
[ ! -t 0 ] && return

# local paths
if [ $EUID -eq 0 ]; then
  add_path PATH /sbin before
  add_path PATH /usr/sbin before
  add_path PATH /usr/local/sbin before
  add_path PATH /opt/local/sbin before
fi

# re-order this early
add_path PATH /usr/local/bin before
add_path PATH ~/.bin
add_path INFOPATH /opt/local/share/info/emacs before

# developer bin
add_path PATH /Applications/Xcode.app/Contents/Developer/usr/bin
add_path PATH /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin

# developer man pages
add_path MANPATH /Applications/Xcode.app/Contents/Developer/usr/share/man
add_path MANPATH /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man

# macports devel directories
if [ -d /opt/local/lib ]; then
  add_path PKG_CONFIG_PATH "/opt/local/lib/pkgconfig"
  add_path ACLOCAL_PATH "/opt/local/share/aclocal"
fi

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
    /usr/bin/ssh-add -A
  }
fi

shopt -s extglob histappend

# Local Variables:
# sh-basic-offset: 2
# indent-tabs-mode: nil
# End:
