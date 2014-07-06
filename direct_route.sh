#!/bin/bash

set -e

gateway=$(LANG=C ifconfig eth0 | grep "inet addr" |cut -f2 -d:|cut -f1 -d\ )
echo "Identified gateway as '$gateway'"
if [ -z "$gateway" ]; then
	echo "E: Could not identify gateway via ifconfig eth0"
	exit 1
fi

function ipdirect () {
	ip=$1
	if ! ip route list table freifunk | grep -q "$ip"; then
		echo "I: Adding route for $ip via $gateway for table freifunk"
		#ip route add $ip via 141.101.36.1 table freifunk
		ip route replace $ip via 141.101.36.1 table freifunk
	else 
		echo "I: Route for $ip is existing - skipped"
	fi
}

function ipindirect () {
	ip=$1
	if ! ip route list table freifunk | grep -q "$ip"; then
		echo "I: Route for $ip not existing in table freifunk - skipped"
	else
		echo "I: Removing route for $ip via $gateway for table freifunk"
		echo ip route del $ip via 141.101.36.67 table freifunk
		ip route del $ip table freifunk || echo "Ignored"
	fi
	if ! ip route list | grep -q "$ip"; then
		echo "I: Route for $ip not existing - skipped"
	else
		echo "I: Removing route for $ip via $gateway for table freifunk"
		echo ip route del $ip via 141.101.36.67
		ip route del $ip || echo "Ignored"
	fi
}

IPs=$(cat <<EOIPS 
google-public-dns-a.google.com
www.google.com
google.com
google.de
www.google.de
apis.google.de
spiegel.de
www.spiegel.de
mail.google.com
gmail.com
spotify.com
www.spotify.com
arte.tv
info.arte.tv
future.arte.tv
creative.arte.tv
concert.arte.tv
cinema.arte.tv
www.arte.tv
tagesschau.de
www.tagesschau.de
ndr.de
www.ndr.de
zdf.de
www.zdf.de
spotify.com
www.spotify.com
ftp.de.debian.org
zatoo.com
www.zatoo.com
amazon.de
www.amazon.de
volksbank-luebeck.de
www.volksbank-luebeck.de
volksbank-eutin.de
www.volksbank-eutin.de
github.com
last.fm
www.last.fm
lastfm.de
www.lastfm.de
google-analytics.com
www.google-analytics.com
facebook.com
www.facebook.com
gmx.de
gmx.net
www.gmx.de
www.gmx.net
navigator.gmx.net
github.com
www.github.com
ostholstein.freifunk.net
gw1.ostholstein.freifunk.net
gw2.ostholstein.freifunk.net
freshmeat.net
bronline.de

EOIPS
)

for n in $IPs
do
	if false; then
		echo "I: Removing $IP direct link"
		if false; then
			for IP in $(ip route list table freifunk | cut -f1 -d\ ) 
			do
				ipindirect $IP
			done
		else
			for IP in $(ip route | grep -v default | grep eth0 | grep -v scope)
			do
				ipindirect $IP
			done
		fi
	else
		for IP in $(host $n |grep "has address" | cut -f4 -d\ )
		do
			#echo "$n : $IP"
			ipdirect $IP
		done
	fi
done
