#!/bin/bash

#if [ "help" = "$1" ]  -o [ "--help" = "$1" ]; then
if [ "help" = "$1" -o  "-h" = "$1" -o "--help" = "$1" ] ; then
	cat << EOHELP
Usage: $(basename $0) does not take any arguments

This script is meant to be executed on a gateway or a web server and
prepare the firewall to distinguish nodes with Internet access from those
that are meshing. Also, the nodes with direct access that are needed
as an uplink should be distinguished.

The output are commands for ip6tables that shall grant access to
those routers in the network for which an update has no downstream
consequences. This shall be helpful in a scenario that induces
an incompatible update.

EOHELP
	exit
fi

set -e

PREFIX=/tmp/macfilter_

if [ ! -r ${PREFIX}tracelist ]; then
	batctl o|awk '{print $1}' | while read i
	do
		#echo $i
		echo -n "$i " && echo $(( $(batctl tr $i|wc -l) -1 ))
	done > ${PREFIX}tracelist
fi

grep '2$' ${PREFIX}tracelist | cut -f1 -d\  | sort > ${PREFIX}candidates
grep '3$' ${PREFIX}tracelist | cut -f1 -d\  | sort > ${PREFIX}meshing

cat ${PREFIX}meshing | while read macaddress
do
	batctl tr $macaddress | awk '{print $2}' 
done | sort > ${PREFIX}neededForMeshing

join --check-order -v 1  ${PREFIX}candidates  ${PREFIX}neededForMeshing > ${PREFIX}permitted


cat ${PREFIX}permitted | while read macaddress
do
	echo /sbin/ip6tables -A INPUT -p tcp -i bat0 --destination-port 80 -m mac --mac-source $macaddress -j ACCEPT
done > ${PREFIX}commands
echo "/sbin/ip6tables -A INPUT -p tcp -i bat0 --destination-port 80 -j REJECT" >> ${PREFIX}commands

echo "First 5 lines:"
head -n 5 ${PREFIX}commands
echo "Find all the commands to execute in '${PREFIX}commands'".
