#!/bin/dash

LOGFILE=/var/log/opensshRestart.log

TEE=/usr/bin/tee
DATE=/bin/date
IP=/sbin/ip

if [ -f /var/run/openvpn.mullvad.pid ] && /sbin/ifconfig mullvad | grep -q inet; then
	#echo ok
	defaultrouteno=$(/sbin/ip route list table freifunk |grep default | wc -l)
else
	$DATE | $TEE -a $LOGFILE
	echo "* Restart" | $TEE -a $LOGFILE
	/etc/init.d/openvpn restart | $TEE -a $LOGFILE
	sleep 10
	defaultrouteno=0
fi
#echo "I: defaultrouteno: $defaultrouteno"
if [ 0 -eq $defaultrouteno ];  then
	mullvadip=$(LANG=C /sbin/ifconfig mullvad | head -n 2 |grep inet|tr " " "\n" | grep addr | cut -f2 -d:)
	$DATE | $TEE -a $LOGFILE
	if [ "x$mullvadip" != "x" ]; then
		$IP route replace default via $mullvadip table freifunk | $TEE -a $LOGFILE
		echo "* I: Update to $mullvadip" | $TEE -a $LOGFILE
	else
		echo "* E: Could not determine mullvadip" | $TEE -a $LOGFILE
	fi
fi
