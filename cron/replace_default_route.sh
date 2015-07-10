#!/bin/dash

LOGFILE=/var/log/opensshRestart.log



if [ -f /var/run/openvpn.mullvad.pid ] && ifconfig mullvad | grep -q inet; then
	echo ok
	defaultrouteno=$(ip route list table freifunk |grep default | wc -l)
else
	date >> $LOGFILE
	echo "* Restart" >> $LOGFILE
	/etc/init.d/openvpn restart >> $LOGFILE
	sleep 10
	defaultrouteno=0
fi
#echo "I: defaultrouteno: $defaultrouteno"
if [ 0 -eq $defaultrouteno ];  then
	mullvadip=$(LANG=C ifconfig mullvad | head -n 2 |grep inet|tr " " "\n" | grep addr | cut -f2 -d:)
	date >> $LOGFILE
	if [ "x$mullvadip" != "x" ]; then
		ip route replace default via $mullvadip table freifunk
		echo "I: Updated default route to mullvad IP: $mullvadip"
		echo "* Update to $mullvadip" >> $LOGFILE
	else
		echo "E: could not determine mullvadip"
		echo "* could not determine mullvadip" >> $LOGFILE
	fi
fi
