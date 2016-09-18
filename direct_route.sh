#!/bin/bash

set -e

GREP=/bin/grep
SED=/bin/sed
CUT=/usr/bin/cut
IP=/sbin/ip
AWK=/usr/bin/awk
SORT=/usr/bin/sort
TEE=/usr/bin/tee
HOST=/usr/bin/host
IFCONFIG=/sbin/ifconfig

export LANG=C

IPv6block=#

DEBUG=

if [ -f /etc/default/direct_route ]; then . /etc/default/direct_route; fi

DEVICE=eth0
if $IFCONFIG|$GREP -q eth0.101; then
    DEVICE=eth0.101
elif $IFCONFIG|$GREP -q enp4s0; then
    DEVICE=enp4s0
fi
#echo "Device='$DEVICE'"

gateway=$(LANG=C $IP address show dev $DEVICE | $GREP "inet " | $AWK '{print $2}' | $CUT -f1 -d/ )
gateway6=$(LANG=C $IP address show dev $DEVICE | $GREP "inet6 " | $AWK '{print $2}' | $CUT -f1 -d/ | $GREP -v "^fe80:")

#if [ -z "$gateway" ]; then
#	gateway=$(LANG=C $IFCONFIG eth0.101|$GREP "inet "| sed -e 's/addr://'|$AWK '{print $2}')
#	gateway6=$(LANG=C $IFCONFIG eth0.101|$GREP "inet6 "| sed -e 's/addr://'|$AWK '{print $2}' | $GREP -v "^fe80:")
#	if [ -z "$gateway" ]; then
#		echo "E: Could not identify gateway via ifconfig eth0 or ifconfig eth0.101"
#		exit 1
#	fi
#fi

if [ -z "$gateway" ]; then
	echo "E: Could not identify gateway"
	exit 3
fi

if [ -z "$gateway6" ]; then
	echo "E: Could not identify gateway for IPv6"
	exit 3
fi

echo -n "Identified gateway as '$gateway'"

via=$(LANG=C $IP route|$GREP default|cut -f3 -d\ )
via6=$(echo $gateway6|$SED -e 's/0$/1/' -e 's/::$/::1/')
#echo "via: $via"
if [ -z "$via" ]; then
	via=$(echo $gateway|$CUT -f 1,2,3 -d .).1
fi

if [ -z "$via" -o ".1" = "$via" ]; then
	echo
	echo "E: Could not determine router through which to exit - yielded '$via'"
	exit 1
fi

echo " routing via '$via' and '$via6'"

IIF=bat0
anomizer=$(LANG=C $IP addr show mullvad | $GREP "inet "| $CUT -f1 -d/| $AWK '{print $2}')
anomizer6=$(LANG=C $IP addr show mullvad | $GREP "inet6 "| $CUT -f1 -d/| $AWK '{print $2}')
anomizer_via6=$(echo $anomizer|$SED -e 's/0$/1/' -e 's/::$/::1/')
echo "Anonmizer is IPv4 $anomizer and IPv6 '$anomizer6'"

echo "Resetting anonymizer to route via '$anomizer'"
echo -n " * IPv4 " && $IP -4 route replace default via $anomizer table freifunk && echo "[ok]"
if [ -z  "$IPv6block" ]; then
	echo -n " * IPv6 " && $IP -6 route replace default via $anomizer_via6 table freifunk  && echo "[ok]"
else
	echo "W: Ignoring all IPv6 redirections"
fi

function ipdirect () {
	ipaddress=$1

	if [ -z "$ipaddress" ]; then
		echo "E: empty IP address passed internally"
	fi

	if echo $ipaddress | grep -q ":"; then

		# IPv6

		if [ -z "$IPv6block" ]; then
			if ! $IP -6 route get $ipaddress from fd73:111:e824::2:1 iif $IIF | $GREP -q $DEVICE; then
				echo "I: Adding direct route for IPv6 $ipaddress ($IP route replace $ipaddress via $via6 table freifunk)"
				$IP route replace $ipaddress via $via6 table freifunk
			else 
				echo "I: Route for '$ipaddress' is existing - skipped"
			fi
		else
			echo "I: Ignoring all IPv6 addresses: '$ipaddress'"
		fi

	else

		# IPv4
	
		if [ "$ipaddress" = "$gateway" ]; then
			echo "W: Skipping direct assignment to *myself*"
        	else
			if ! $IP route get $ipaddress from 10.135.8.100 iif $IIF | $GREP -q $DEVICE; then
				echo "I: Adding direct route for $ipaddress ($IP route replace $ipaddress via $via table freifunk)"
				$IP route replace $ipaddress via $via table freifunk
			else 
				echo "I: Route for $ipaddress is existing - skipped"
			fi
		fi
	fi
}

function ipindirect () {
	ipaddress=$1
	if ! $IP route list table freifunk | $GREP -q "$ipaddress"; then
		echo "I: Route for $ipaddress not existing in table freifunk - skipped"
	else
		echo "I: Removing route for $ipaddress via $gateway for table freifunk"
		#echo "$IP route del $ipaddress via $gateway table freifunk"
		echo "$IP route del $ipaddress table freifunk"
		$IP route del $ipaddress table freifunk || echo "Ignored"
	fi
	if ! $IP route list | $GREP -q "$ipaddress"; then
		echo "I: Route for $ipaddress not existing - skipped"
	else
		echo "I: Removing route for $ipaddress via $gateway for table freifunk"
		echo "$IP route del $ipaddress #via $gateway"
		$IP route del $ipaddress || echo "Ignored"
	fi
}


echo "I: learning white-listed URLs/IPs"

i=0
IPs=$(cat $(dirname $0)/deanonymise.txt | $GREP -v ^# | $AWK '{print $1}' | $TEE bla.txt | $SORT -u )

for n in $IPs
do
	i=$(($i+1))
	echo "$i: $n"

	if [ "Binary" = "$n" ]; then
		echo "E: Stumbled into 'Binary' host - no idea how, yet - skipping"

	else

		if false; then
			echo "I: Removing direct link"
			if false; then
				for ipaddress in $($IP route list table freifunk | $CUT -f1 -d' ' ) 
				do
					ipindirect $ipaddress
				done
			else
				for ipaddress in $($IP route | $GREP -v default | $GREP $DEVICE | $GREP -v scope)
				do
					ipindirect $ipaddress
				done
			fi
		else
			if [ -z "$(echo $n | tr -d '.0-9/')" ]; then
				echo "I: Interpreting '$n' as IP Number"
				ipdirect $n
			else
				echo "I: Interpreting '$n' as host"
			if ! hostoutput=$($HOST $n); then
					echo "E: could not resolve address for '$n', check for typo"
				else
					if [ -n "$DEBUG" ]; then
						echo "I: hostoutput: $hostoutput"
					fi
					for ipaddress in $(echo "$hostoutput" |$GREP "has address" | $CUT -f4 -d' ' )
					do
						ipdirect $ipaddress
					done
					for ipaddress in $(echo "$hostoutput" |$GREP "has IPv6 address" | $CUT -f5 -d' ' )
					do
						ipdirect $ipaddress
					done
				fi
			fi
		fi
	fi  # if binary
done

echo "[ok]"

