# -*- mode: sh; sh-basic-offset: 2; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sw=2 ts=2:
#
# zz-serial-resize.sh v1.0 - add resize to shell if on serial port

# Skip all for noninteractive shells.
[[ -t 0 ]] || return 0

[[ $(tty) =~ /dev/tty(S|USB)[0-9]+ ]] && command -v >/dev/null resize ||
    return 0

[[ $PROMPT_COMMAND ]] && PROMPT_COMMAND+="; resize >/dev/null"
