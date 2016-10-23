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

The script needs to be adapted to a local setup. It starts with the
IPv6prefix for your Freifunk setup but also the interpretation of 
direct vs indirect contact with the webserver may vary if the webserver
serves as an uplink itself.

EOHELP
	exit
fi

set -e

PREFIX=/tmp/macfilter_
IPv6prefix=fd73:0111:e824:0000

if [ ! -r ${PREFIX}01_tracelist ]; then
	echo "I: Determining tracelist"
	batctl o|awk '{print $1}' | while read i
	do
		#echo $i
		echo -n "$i " && echo $(( $(batctl tr $i|wc -l) -1 ))
	done | grep ":" > ${PREFIX}01_tracelist
else
	echo "I: Reusing previous tracelist at '${PREFIX}01_tracelist', remove for an update."
fi

echo "I: Separating direct and indirectly connecting devices"

grep '2$' ${PREFIX}01_tracelist | cut -f1 -d\  | sort > ${PREFIX}02_candidates
grep '3$' ${PREFIX}01_tracelist | cut -f1 -d\  | sort > ${PREFIX}02_meshing

echo "I: Negatively selecting routers that are uplinks for others"

cat ${PREFIX}02_meshing | while read macaddress
do
	batctl tr $macaddress | awk '{print $2}' 
done | sort > ${PREFIX}03_neededForMeshing

join --check-order -v 1  ${PREFIX}02_candidates  ${PREFIX}03_neededForMeshing > ${PREFIX}04_permitted

echo "I: Creating .sh script to direct the firewall"

echo "#!/bin/bash -e" > ${PREFIX}commands
echo "/sbin/ip6tables -D INPUT -p tcp -i bat0 --destination-port 80 -j determines-autoupdates || echo 'Fail delete of reference ignored'" >> ${PREFIX}commands 
echo "ip6tables -F determines-autoupdates && ip6tables -X determines-autoupdates || echo 'Fail delete of prior chain ignored.'" >> ${PREFIX}commands
echo "ip6tables -N determines-autoupdates" >> ${PREFIX}commands
cat ${PREFIX}04_permitted | while read macaddress
do
	#echo /sbin/ip6tables -A determines-autoupdates -i bat0 -m mac --mac-source $macaddress -j ACCEPT
	ipv6address="$IPv6prefix:$(echo $macaddress | cut -f1,2 -d: | tr --delete ':'):$(echo $macaddress | cut -f3 -d:)ff:fe$(echo $macaddress | cut -f4 -d:):$(echo $macaddress | cut -f5,6 -d: | tr --delete ':' )"
	echo /sbin/ip6tables -A determines-autoupdates -i bat0 -s $ipv6address -j ACCEPT
done >> ${PREFIX}commands
echo "/sbin/ip6tables -m comment --comment 'rejected router for update' -A determines-autoupdates -m limit --limit 5/min -j LOG --log-prefix Denied_Update: --log-level 7" >> ${PREFIX}commands
echo "/sbin/ip6tables -A determines-autoupdates -p tcp -i bat0 --destination-port 80 -j REJECT" >> ${PREFIX}commands
echo "/sbin/ip6tables -I INPUT -p tcp -i bat0 --destination-port 80 -j determines-autoupdates " >> ${PREFIX}commands
chmod +x ${PREFIX}commands

echo "First and last 5 lines:"
head -n 5 ${PREFIX}commands
echo "..."
tail -n 5 ${PREFIX}commands
echo "Find all the commands to execute in '${PREFIX}commands'"
