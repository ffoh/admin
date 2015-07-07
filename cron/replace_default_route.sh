#!/bin/dash

defaultrouteno=$(ip route list table freifunk |grep default | wc -l)
#echo "I: defaultrouteno: $defaultrouteno"
if [ 0 -eq $defaultrouteno ];  then
	mullvadip=$(LANG=C ifconfig mullvad | head -n 2 |grep inet|tr " " "\n" | grep addr | cut -f2 -d:)
	if [ "x$mullvadip" != "x" ]; then
		echo ip route replace default via $mullvadip table freifunk
		echo "I: Mullvad IP: $mullvadip"
	else
		echo "E: could not determine mullvadip"
	fi
fi
