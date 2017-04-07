#!/bin/sh

set -e

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

IFCONFIG=/sbin/ifconfig
GREP=/bin/grep
IP=/sbin/ip
BATCTL=/usr/sbin/batctl
PING=/bin/ping

DEVICE=eth0
if $IFCONFIG|$GREP -q eth0.101; then
    DEVICE=eth0.101
elif $IFCONFIG|$GREP -q enp4s0; then
    DEVICE=enp4s0
fi      


do_start () {
	echo "I: freifunk setting up iptables - sleeping 60 seconds"

	sleep 60

	cd $ADMINDIR
	git pull

	$IP -6 rule add from all iif bat0 lookup freifunk
	$IP -4 rule add from all iif bat0 lookup freifunk

	$ADMINDIR/iptables.sh && echo "iptables OK" || echo "iptables failed"

	(echo "Sleeping 5 seconds" && sleep 5 && cd $ADMINDIR && nice ./direct_route.sh > /dev/null)&

	echo "I: Stopping alfred if running"
	for i in $(pidof alfred); do
		echo "W: Killing alfred with pid $i"
		kill $i
	done
	echo "I: Starting alfred to listen on bat0"
	/usr/sbin/alfred -i bat0 > /dev/null &
}

case "$1" in
  start)
	do_start
	;;
  status)
	for cmd in "$BATCTL gw" "$IFCONFIG mullvad" "$IP route show" "$IP rule" "$PING -c 1 8.8.8.8 -I mullvad" "$PING -c 1 8.8.8.8 -I $DEVICE"
	do
		echo
		echo "I: $cmd"
		echo $( $cmd )
	done
	echo
	echo "I: $IP route show table freifunk | grep default"
	$IP route show table freifunk | grep default
	;;
  restart|reload|force-reload)
	echo "Error: argument '$1' not supported" >&2
	exit 3
	;;
  stop)
	# No-op
	echo "W: freifunk stop not yet implemented"
	$BATCTL gw client
	
	;;
  *)
	echo "Usage: $0 start|status" >&2
	exit 3
	;;
esac

echo "[ ok ]"
