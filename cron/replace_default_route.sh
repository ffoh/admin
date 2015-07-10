#!/bin/dash

LOGFILE=/var/log/opensshRestart.log



if [ -f /var/run/openvpn.mullvad.pid ] && /sbin/ifconfig mullvad | grep -q inet; then
	echo ok
	defaultrouteno=$(ip route list table freifunk |grep default | wc -l)
else
	date | tee -a $LOGFILE
	echo "* Restart" | tee -a $LOGFILE
	/etc/init.d/openvpn restart | tee -a $LOGFILE
	sleep 10
	defaultrouteno=0
fi
#echo "I: defaultrouteno: $defaultrouteno"
if [ 0 -eq $defaultrouteno ];  then
	mullvadip=$(LANG=C /sbin/ifconfig mullvad | head -n 2 |grep inet|tr " " "\n" | grep addr | cut -f2 -d:)
	date | tee -a $LOGFILE
	if [ "x$mullvadip" != "x" ]; then
		ip route replace default via $mullvadip table freifunk | tee -a $LOGFILE
		echo "* I: Update to $mullvadip" | tee -a $LOGFILE
	else
		echo "* E: Could not determine mullvadip" | tee -a $LOGFILE
	fi
fi
