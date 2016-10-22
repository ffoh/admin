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
	done | grep ":" > ${PREFIX}01_tracelist
fi

grep '2$' ${PREFIX}01_tracelist | cut -f1 -d\  | sort > ${PREFIX}02_candidates
grep '3$' ${PREFIX}01_tracelist | cut -f1 -d\  | sort > ${PREFIX}02_meshing

cat ${PREFIX}02_meshing | while read macaddress
do
	batctl tr $macaddress | awk '{print $2}' 
done | sort > ${PREFIX}03_neededForMeshing

join --check-order -v 1  ${PREFIX}02_candidates  ${PREFIX}03_neededForMeshing > ${PREFIX}04_permitted

echo "#!/bin/bash -e" > ${PREFIX}commands
echo "/sbin/ip6tables -D INPUT -p tcp -i bat0 --destination-port 80 -j determines-autoupdates || echo 'Fail delete of reference ignored'" >> ${PREFIX}commands 
echo "ip6tables -F determines-autoupdates && ip6tables -X determines-autoupdates || echo 'Fail delete of prior chain ignored.'" >> ${PREFIX}commands
echo "ip6tables -N determines-autoupdates" >> ${PREFIX}commands
cat ${PREFIX}04_permitted | while read macaddress
do
	echo /sbin/ip6tables -A determines-autoupdates -i bat0 -m mac --mac-source $macaddress -j ACCEPT
done >> ${PREFIX}commands
echo "/sbin/ip6tables -A determines-autoupdates -p tcp -i bat0 --destination-port 80 -j REJECT" >> ${PREFIX}commands
echo "/sbin/ip6tables -A INPUT -p tcp -i bat0 --destination-port 80 -j determines-autoupdates " >> ${PREFIX}commands
chmod +x ${PREFIX}commands

echo "First and last 5 lines:"
head -n 5 ${PREFIX}commands
echo "..."
tail -n 5 ${PREFIX}commands
echo "Find all the commands to execute in '${PREFIX}commands'"
