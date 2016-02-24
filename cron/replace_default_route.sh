#!/bin/dash

LOGFILE=/var/log/opensshRestart.log

TEE=/usr/bin/tee
DATE=/bin/date
IP=/sbin/ip
GREP=/bin/grep
BATCTL=/usr/sbin/batctl

if /bin/ps aux|$GREP openvpn|$GREP -q mullvad && /sbin/ifconfig mullvad | $GREP -q inet; then
	#echo ok
	defaultrouteno=$(/sbin/ip route list table freifunk |$GREP default | wc -l)
else
	$DATE | $TEE -a $LOGFILE
	echo "* Restart" | $TEE -a $LOGFILE
	/etc/init.d/openvpn restart | $TEE -a $LOGFILE
	sleep 10
	defaultrouteno=0
fi
#echo "I: defaultrouteno: $defaultrouteno"
if [ 0 -eq $defaultrouteno ];  then
	mullvadip=$(LANG=C ip addr show mullvad |grep inet|cut -f1 -d/|awk '{print $2}')
	$DATE | $TEE -a $LOGFILE
	if [ "x$mullvadip" != "x" ]; then
		$IP route replace default via $mullvadip table freifunk | $TEE -a $LOGFILE
		echo "* I: Update to $mullvadip" | $TEE -a $LOGFILE
	else
		echo "* E: Could not determine mullvadip" | $TEE -a $LOGFILE
		exit 0
	fi
fi




if [ "client" = $($BATCTL gw | cut -f1 -d\ ) ]; then
	if $BATCTL gw server 100Mbit/100Mbit; then
		echo "* I: success turning batctl gw server on (from client state)" | $TEE -a $LOGFILE
	else
		echo "* E: failed turning batctl gw server on (from client state)" | $TEE -a $LOGFILE
	fi
elif [ "off" = $($BATCTL gw | cut -f1 -d\ ) ]; then
	if $BATCTL gw server 100Mbit/100Mbit; then
		echo "* I: success turning batctl gw server on (from off state)" | $TEE -a $LOGFILE
	else
		echo "* E: failed turning batctl gw server on (from off state)" | $TEE -a $LOGFILE
	fi
fi
