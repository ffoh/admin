#!/bin/sh

### BEGIN INIT INFO
# Provides:          freifunk
# Required-Start:    $local_fs $time $network openvpn $named
# Required-Stop:     $local_fs $time $network openvpn $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Sets up Freifunk gateway activity
# Description:
### END INIT INFO

ADMINDIR=/root/admin

PATH=/sbin:/usr/sbin:/bin:/usr/bin
[ -f /etc/default/freifunk ] && . /etc/default/freifunk

. /lib/lsb/init-functions

do_start () {
	echo "I: freifunk setting up iptables"

	sleep 60

	cd $ADMINDIR
	git pull

	$ADMINDIR/iptables.sh

	(sleep 5; nice $ADMINDIR/direct_route.sh > /dev/null)&

	alfred -m -i bat0 > /dev/null &

}

case "$1" in
  start)
	do_start
	;;
  status)
	for cmd in "batctl gw" "ifconfig mullvad" "ip route show table freifunk | grep default" "ip route show" "ip rule" "ping -c 1 8.8.8.8 -I mullvad" "ping -c 1 8.8.8.8 -I eth0"
	do
		echo
		echo "I: $cmd"
		echo $($cmd)
	done
	;;
  restart|reload|force-reload)
	echo "Error: argument '$1' not supported" >&2
	exit 3
	;;
  stop)
	# No-op
	echo "W: freifunk stop not yet implemented"
	batctl gw client
	
	;;
  *)
	echo "Usage: $0 start|status" >&2
	exit 3
	;;
esac


