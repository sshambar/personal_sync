
[ ! -t 0 ] && return

iperfs() {
  [ -z "$1" ] && echo "iperfs <bind-ip>" && return 1
  command -v iperf3 >/dev/null || { echo "install iperf3" && return 1; }
  iperf3 -f m -s -B "$1"
}

iperfc() {
  [ -z "$1" ] && echo "iperfc <host>" && return 1
  command -v iperf3 >/dev/null || { echo "install iperf3" && return 1; }
  iperf3 -f m -c "$1"
}


