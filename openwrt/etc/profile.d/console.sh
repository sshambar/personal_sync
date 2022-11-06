[[ $PS1 ]] && [[ "$(id -u)" == 0 ]] &&
  alias console='screen -fn /dev/ttyUSB0 115200,crtscts'

[[ "$(ps 2>/dev/null hotty $$)" == ttyS0 ]] && command -v >/dev/null resize &&
  resize >/dev/null

