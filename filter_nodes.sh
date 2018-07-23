#!/bin/bash

#if [ "help" = "$1" ]  -o [ "--help" = "$1" ]; then
if [ "help" = "$1" -o  "-h" = "$1" -o "--help" = "$1" ] ; then
	cat << EOHELP
Usage: $(basename $0) [whitelist]

This script is meant to be executed on a gateway or a web server and
prepare the firewall to distinguish nodes with Internet access from those
that are meshing. Also, the nodes with direct access that are needed
as an uplink should be distinguished.

The output are commands for ip6tables that shall grant access to the
host running the script only for those routers in the network for which
an update has no downstream consequences. This shall be helpful in a
scenario that induces the transition to an incompatible protocol.

The script needs to be adapted to a local setup. It starts with the
IPv6prefix for your Freifunk setup but also the interpretation of 
direct vs indirect contact with the webserver may vary if the webserver
serves as an uplink itself.

EOHELP
	exit 1
fi

set -e

######## ADJUST HERE ###########################################
IPv6prefix="fd73:0111:e824:0000::"

	# mode: Set to anything but the empty string to avoid
	#       the deletion of previously accepted hosts.
mode=ExtendQueue
minMeshDepth=0

######## NO CHANGE SHOULD BE REQUIRED BELOW THIS LINE  #########
PREFIX="/tmp/macfilter_"


# testing for availability of ipv6 IP number tool
ipv6calc=/usr/bin/ipv6calc
if [ ! -x "$ipv6calc" ]; then
	echo "E: Please install ipv6calc, e.g. from the cognate package in Debian ."
	exit 1
fi

# Deciding root of tree of connected MAC addresses - whitelist of batctl
if [ -n "$1" ]; then

	if [ ! -r "$1" ]; then
		echo "E: Could not read whitelisted MAC addresses on '$1'"
		exit 1
	fi

	echo "I: Building candidate list from whitelist '$1'"

	grep -v "^#" $1 | egrep "^..:..:..:..:..:.." | while read mac
	do
		batctl tr $mac | tail -n 1 | awk '{print $2}'
	done | egrep "^..:..:..:..:..:.." | sort -u > ${PREFIX}01_tracelist

elif [ ! -r ${PREFIX}01_tracelist ]; then
	echo "I: Determining tracelist"
	batctl o|awk '{print $1}' | grep -v "B.A.T.M.A.N" | grep -v riginator | while read i
	do
		#echo $i
		echo -n "$i " && echo $(( $(batctl tr $i|wc -l) -1 ))
	done | egrep "^..:..:..:..:..:.." | sort -u > ${PREFIX}01_tracelist
else
	echo "I: Reusing previous tracelist at '${PREFIX}01_tracelist', remove for an update."
fi

echo "I: Separating direct and indirectly connecting devices"

grep "$(($minMeshDepth+0))\$" ${PREFIX}01_tracelist | cut -f1 -d\  | sort -u > ${PREFIX}02_candidates
grep "$(($minMeshDepth+1))\$" ${PREFIX}01_tracelist | cut -f1 -d\  | sort -u > ${PREFIX}02_meshing
grep -v "$(($minMeshDepth+0))\$" ${PREFIX}01_tracelist | cut -f1 -d\  | sort -u > ${PREFIX}02_meshing_any

echo "I: Negatively selecting routers that are uplinks for others"

cat ${PREFIX}02_meshing_any | while read macaddress
do
	# avoid to deselect one's own mac address -> tail
	batctl tr $macaddress | tail -n +3 | head -n -1 | awk '{print $2}' 
done | sort -u > ${PREFIX}03_neededForMeshing

#join --check-order -v 1  ${PREFIX}02_candidates  ${PREFIX}03_neededForMeshing > ${PREFIX}04_permitted
join --check-order -v 1  ${PREFIX}01_tracelist  ${PREFIX}03_neededForMeshing > ${PREFIX}04_permitted

echo "I: Creating .sh script to direct the firewall"

echo "#!/bin/bash -e" > ${PREFIX}commands
if [ -z "$mode" ]; then
	# Start queue from scratch and delete old bits
	echo "/sbin/ip6tables -D INPUT -p tcp -i bat0 --destination-port 80 -j determines-autoupdates || echo 'Fail delete of reference ignored'" >> ${PREFIX}commands 
batmantranslation="/sys/kernel/debug/batman_adv/bat0/transtable_global"
	echo "ip6tables -F determines-autoupdates && ip6tables -X determines-autoupdates || echo 'Fail delete of prior chain ignored.'" >> ${PREFIX}commands
	echo "ip6tables -N determines-autoupdates" >> ${PREFIX}commands
fi

cat ${PREFIX}04_permitted | while read originmac
do
	originipv6address=$(ipv6calc --action prefixmac2ipv6 --in prefix+mac --out ipv6addr $IPv6prefix $originmac)
	clientmacs=$(grep "$originmac" $batmantranslation | cut -f3 -d\  )

	echo "/sbin/ip6tables -I determines-autoupdates -i bat0 -s $originipv6address -m comment --comment 'origin of $(echo $clientmacs | tr "\n" " ")' -j ACCEPT"

	if [ -n "$clientmacs" ]; then
		for clientmac in $clientmacs; do
			clientipv6address=$(ipv6calc --action prefixmac2ipv6 --in prefix+mac --out ipv6addr $IPv6prefix $clientmac)
			echo "/sbin/ip6tables -A determines-autoupdates -i bat0 -s $clientipv6address -m comment --comment 'client of $originmac' -j ACCEPT"
		done
	else
		echo "# E: Could not find client for origin '$originmac'"
	fi
done >> ${PREFIX}commands

if [ -z "$mode" ]; then
	echo "/sbin/ip6tables -m comment --comment 'rejected router for update' -A determines-autoupdates -m limit --limit 5/min -j LOG --log-prefix Denied_Update: --log-level 7" >> ${PREFIX}commands
	echo "/sbin/ip6tables -A determines-autoupdates -p tcp -i bat0 --destination-port 80 -j REJECT" >> ${PREFIX}commands
	echo "/sbin/ip6tables -I INPUT -p tcp -i bat0 --destination-port 80 -j determines-autoupdates " >> ${PREFIX}commands
fi
chmod +x ${PREFIX}commands

echo "First and last 5 lines:"
head -n 5 ${PREFIX}commands
echo "..."
tail -n 5 ${PREFIX}commands
echo "Find all the commands to execute in '${PREFIX}commands'"
