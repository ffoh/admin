#!/bin/sh

set -e

### BEGIN INIT INFO
# Provides:          freifunk
# Required-Start:    $local_fs $time $network openvpn $named fastd
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

	$ADMINDIR/iptables.sh

	(sleep 5 && cd $ADMINDIR && nice ./direct_route.sh > /dev/null)&

	killall -q alfred
	alfred -m -i bat0 > /dev/null &

}

case "$1" in
  start)
	if ! ip addr show ffoh-mesh-vpn > /dev/null ; then
		echo "E: fastd not set up properly"
		exit 3
	fi

	do_start
	;;
  status)
	for cmd in "batctl gw" "ifconfig bat0" "ifconfig mullvad" "$IP route show" "$IP rule" "ping -c 1 8.8.8.8 -I mullvad" "ping -c 1 8.8.8.8 -I $DEVICE"
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
	batctl gw client
	
	;;
  *)
	echo "Usage: $0 start|status" >&2
	exit 3
	;;
esac

echo "[ ok ]"
