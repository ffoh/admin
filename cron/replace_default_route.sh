#!/bin/dash

LOGFILE=/var/log/opensshRestart.log

if ifconfig | grep -q mullvad; then
	#echo ok
	defaultrouteno=$(ip route list table freifunk |grep default | wc -l)
else
	/etc/init.d/openvpn restart
	sleep 5
	date >> $LOGFILE
	echo "* Restart" >> $LOGFILE
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
