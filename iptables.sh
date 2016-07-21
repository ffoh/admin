#!/bin/bash

set -e

WWWip="109.75.177.24"
Mailip="109.75.177.24"

ThisIsGateway="no"
ThisIsWebserver="no"
ThisIsMailserver="no"
FreifunkDevice="bat0"

GREP=/bin/grep
EGREP=/bin/egrep
SED=/bin/sed
IP=/sbin/ip
CUT=/usr/bin/cut
AWK=/usr/bin/awk
SORT=/usr/bin/sort
XARGS=/usr/bin/xargs
IFCONFIG=/sbin/ifconfig
IPTABLES=/sbin/iptables
WGET=/usr/bin/wget
ECHO=/bin/echo

for i in $GREP $SED $IP $CUT $AWK $SORT $XARGS $IFCONFIG $IPTABLES $WGET $ECHO
do
	if ! test -x "$i"
	then
		$ECHO "E: Cannot execute '$i'."
		exit 1
	fi
done


GatewayIp4List="141.101.36.19 141.101.36.67 109.75.188.36 109.75.177.17 109.75.184.140 5.9.63.137 109.75.188.10"
#                     gw1          gw2          gw3            gw4          gw5        gw6          gw-test

GatewayIp6List="2a00:12c0:1015:166::1:1 2a00:12c0:1015:166::1:2 2a00:12c0:1015:166::1:3 2a00:12c0:1015:166::1:4 2a00:12c0:1015:166::1:5 2a01:4f8:161:6487::6 2a00:12c0:1015:166::1:7 2a00:12c0:1015:198::1"
#                     gw1                       gw2                       gw3                   gw4                       gw5                gw6                  gw-test

LocalGatewayHostnames="gattywatty01.my-gateway.de"
LocalGatewayIpv4List="192.168.178.113"

DEVICE=eth0
if $IFCONFIG|$GREP -q eth0.101; then
    DEVICE=eth0.101
    ThisIsGateway="yes"
fi

myIP=$(LANG=C $IP addr show $DEVICE|$GREP "inet "| $SED -e 's/addr://'|$AWK '{print $2}'|$CUT -f1 -d/)

if [ -z "$myIP" ]; then
    $ECHO "E: Could not determine this machine's IP address"
    exit
fi

$ECHO "I: myIP=my$IP"

for gw in $GatewayIp4List
do
    if [ "x$gw" = "x$myIP" ]; then
       # this is a gateway machine
       ThisIsGateway="yes"
    fi
done

if [ -x /usr/sbin/apache2 -o "x$myIP"="x$WWWIP" ]; then
    ThisIsWebserver="yes"
else
    for www in $WWWip
    do
        if [ "x$www" = "x$myIP" ]; then
            # this is a Webserver
            ThisIsWebserver="yes"
        fi
    done
fi

if [ "x$myIP" = "x$Mailip" ]; then
    ThisIsMailserver="yes"
fi

function FWboth {
   FW4="/sbin/iptables"
   FW6="/sbin/ip6tables"
   comment=$1
   if [ -n "$comment" ];then
       shift 1
       $ECHO $FW4 -m comment --comment "$comment" $*
       $FW4 -m comment --comment "$comment" $*
       $ECHO $FW6 -m comment --comment "$comment" $*
       $FW6 -m comment --comment "$comment" $*
   else
       $ECHO $FW4 $*
       $FW4 $*
       $FW6 $*
   fi
}

function FW4 {
   FW4="/sbin/iptables"
   #$ECHO $FW4 $*
   comment=$1
   if [ -n "$comment" ]; then
       shift 1
       $ECHO $FW4 -m comment --comment "$comment" $*
       $FW4 -m comment --comment "$comment" $*
   else
       $ECHO $FW4 $*
       $FW4 $*
   fi
}

function FW6 {
   FW6="/sbin/ip6tables"
   #$ECHO $FW6 $*
   comment=$1
   if [ -n "$comment" ];then
       shift 1
       $ECHO $FW6 -m comment --comment "$comment" $*
       $FW6 -m comment --comment "$comment" $*
   else
       $ECHO $FW6 $*
       $FW6 $*
   fi
}

$ECHO "I: reset all prior rules"

FWboth "" -F
FWboth "" -X
FW4 "" -t nat -F

$ECHO "I: Starting with a permissive default, restricted later in case script fails"
FWboth "" -P INPUT   ACCEPT
FWboth "" -P FORWARD ACCEPT
FWboth "" -P OUTPUT  ACCEPT

$ECHO "I: Creating chain named 'log-drop'"
FWboth "" -N log-drop

# may not be a good idea to drop ICMP, in particular not for IPv6
#FWboth "log and drop ICMP" '-A log-drop -m limit --limit 5/min -j LOG --log-prefix Denied_IN: --log-level 7'

# uncomment once important bits are no longer logged
#FWboth "" -A log-drop -j DROP

FWboth "" -N log-drop-out
FWboth "log and drop TCP" '-A log-drop-out -m limit --limit 5/min -j LOG --log-prefix Denied_OUT: --log-level 7'
FWboth "" -A log-drop-out -j DROP

FWboth "Allow related packages" -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

FW4 "dropping weird chinese attacker 1" -s 222.0.0.0/8 -I INPUT -j DROP
FW4 "dropping weird chinese attacker 1" -d 222.0.0.0/8 -I OUTPUT -j DROP
FW4 "dropping weird chinese attacker 2" -s 116.0.0.0/10 -I INPUT -j DROP
FW4 "dropping weird chinese attacker 2" -d 116.0.0.0/10 -I OUTPUT -j DROP

FWboth "dropping telnet " -p tcp --dport 23 -I INPUT -j DROP

$ECHO "I: JA: trust myself on lo"
FWboth "Trusting local host" -A  INPUT -i lo -j ACCEPT

$ECHO "I: JA: trusting all gateway IP4 gateway addresses on eth0"
for gw in $GatewayIp4List
do
	$ECHO -n "       gateway $gw "
	FW4 "Fully_trusting_gateway" -A INPUT -s $gw/32 -j ACCEPT
	$ECHO "- trusted"
done

if [ "yes" = "$ThisIsMailserver" ]; then
    FWboth "Mailservers accept on port 25" -A INPUT -p tcp -m multiport --dports smtp,ssmtp -j ACCEPT 
fi

#$ECHO "I: JA: trusting all gateway IP6 gateway addresses on eth0"
FW6 "Fully trusting all our other gateways" -A INPUT -s 2a00:12c0:1015:166::1:1/120 -j ACCEPT

$ECHO "I: JA fuer Freifunk: PING, FASTD, DNS"
if [ "yes"="$ThisIsGateway" ]; then
   $ECHO "I: Machine recognised as gateway"
   # Trust WWW machine to ping
   FW4 "Freifunk Network - ping from WWW external IP" "-A INPUT -p icmp -s ${WWWip}/32 -j ACCEPT"
   # DNS service
   FWboth "Freifunk Network - DNS" '-A INPUT -p udp -j ACCEPT'
   # Gateways are gateways for fastd and always listen to port 10000 or 11280 or 11426
   FWboth "Freifunk Network - fastd always served" '-A INPUT -p udp --dport 10000 -j ACCEPT'
   FWboth "Freifunk Network - fastd always served" '-A INPUT -p udp --dport 11280 -j ACCEPT'
   FWboth "Freifunk Network - fastd always served" '-A INPUT -p udp --dport 11426 -j ACCEPT'
   # Intercity Gateway
   FWboth "Freifunk Network - tinc for ICVPN" '-A INPUT -p udp --dport 656 -j ACCEPT'
   FWboth "Freifunk Network - tinc for ICVPN" '-A INPUT -p tcp --dport 656 -j ACCEPT'
   #FWboth "Freifunk Network - Web access" -A INPUT -p tcp -i $FreifunkDevice --dport http -j ACCEPT
   FWboth "Freifunk Network - Web access secure" -A INPUT -p tcp -i $FreifunkDevice --dport https -j ACCEPT
   FWboth "Freifunk Network - nodogsplash web" -A INPUT -p tcp -i $FreifunkDevice --dport 2050 -j ACCEPT

   FW4 "Freifunk ICVPN" -A INPUT -s 10.207.0.0/16 -j ACCEPT

   FWboth "Freifunk Network - iperf tests" -A INPUT -p tcp -i $FreifunkDevice --dport 5001 -j ACCEPT
fi

if [ "yes"="$ThisIsWebserver" ]; then
   $ECHO "I: Machine is a webserver"
   # Accept port 10000 when it comes from the network's IP Address
   FWboth "Freifunk Network - fastd from $FreifunkDevice" "-A INPUT -p udp -i $FreifunkDevice --dport 10000 -j ACCEPT"
   # Accept port 11426 when it comes from the network's IP Address - for that MTU
   FWboth "Freifunk Network - fastd from $FreifunkDevice" "-A INPUT -p udp -i $FreifunkDevice --dport 11280 -j ACCEPT"
   # Accept port 11426 when it comes from the network's IP Address - for that MTU
   FWboth "Freifunk Network - fastd from $FreifunkDevice" "-A INPUT -p udp -i $FreifunkDevice --dport 11426 -j ACCEPT"
   for gw in $GatewayIp4List
   do
	   FW4 "fastd from gateway $gw" "-A INPUT -p udp -s $gw --dport 10000 -j ACCEPT"
	   FW4 "fastd from gateway $gw" "-A INPUT -p udp -s $gw --dport 11280 -j ACCEPT"
	   FW4 "fastd from gateway $gw" "-A INPUT -p udp -s $gw --dport 11426 -j ACCEPT"
   done
   for gw in $GatewayIp6List
   do
	   FW6 "fastd from gateway $gw" "-A INPUT -p udp -s $gw --dport 10000 -j ACCEPT"
	   FW6 "fastd from gateway $gw" "-A INPUT -p udp -s $gw --dport 11280 -j ACCEPT"
	   FW6 "fastd from gateway $gw" "-A INPUT -p udp -s $gw --dport 11426 -j ACCEPT"
   done
   FWboth "" '-A INPUT -p udp --dport 16962  -j ACCEPT' ## FIXME: WHAT IS THIS?!? Steffen
   FWboth "From everywhere - Web access" -A INPUT -p tcp --dport http -j ACCEPT
   FWboth "From everywhere - Web access secure" '-A INPUT -p tcp --dport https -j ACCEPT'
fi

FWboth "Freifunk Network - ping from $FreifunkDevice" "-A INPUT -p icmp -i $FreifunkDevice -j ACCEPT"
FW6 "Freifunk Network IPv6 - allowed to do anything" -A INPUT -i $FreifunkDevice -j ACCEPT
FW6 "Freifunk Intercity IPv6 - allowed to ping" -A INPUT -i eth0 -p icmpv6 -j ACCEPT
FW6 "Freifunk Intercity IPv6 - allowed to ping" -A INPUT -i icvpn -p icmpv6 -j ACCEPT

#FWboth "Receive NTP packages" '-A INPUT -p udp -i eth0 --dport ntp -j ACCEPT'
#FWboth "Receive NTP packages" '-A INPUT -p tcp -i eth0 --dport ntp -j ACCEPT'

# Always trust all gateways and Webservers, also for their external IPs
for gw in $GatwayIp4List
do
    FW4 "Freifunk Network - ping from GW external IP" "-A INPUT -p icmp -s $gw/32 -j ACCEPT"
done 
for gw in $WWWip
do
    FW4 "Freifunk Network - ping from www external IP" "-A INPUT -p icmp -s $gw/32 -j ACCEPT"
done 


if [ "yes"="$ThisIsGateway" ]; then
   FWboth "Freifunk Network - dhcpd" '-A INPUT -p udp -i $FreifunkDevice --dport bootps -j ACCEPT'
   FWboth "Freifunk Network - dhcpd" '-A INPUT -p udp -i $FreifunkDevice --dport 11431 -j ACCEPT'
   FWboth "Freifunk Network - dhcpd" '-A INPUT -p udp -i $FreifunkDevice --dport 61703 -j ACCEPT'

   FWboth "Freifunk ICVPN" "-A INPUT -i icvpn -p tcp --sport 179 -j ACCEPT"
   FWboth "Freifunk ICVPN" "-A INPUT -i icvpn -p tcp --dport 179 -j ACCEPT"
fi

FWboth "netperf" -A INPUT -p tcp --dport 12865 -j ACCEPT
FWboth "netperf" -A INPUT -p udp --dport 12865 -j ACCEPT

$ECHO "I: NEIN: FTP"
FWboth "FTP is not configured, should not be listening anyway, but .." '-A INPUT -p tcp --dport ftp -j log-drop'
FWboth "No DNS from outside Freifunk" -A INPUT -p tcp --dport domain -j log-drop

$ECHO "I: JA: SSH, WWW, PING"
FWboth "SSH login possible from everywhere" '-A INPUT -p tcp --dport ssh -j ACCEPT'
FW4 "Report fragmented Pings from outside Freifunk and drop them." '-A INPUT -p icmp --fragment -j ACCEPT'
FWboth "Do accept Pings from outside Freifunk" '-A INPUT -p icmp -j ACCEPT'

$ECHO "I: drop anything else"
FWboth "dropping common hack target, not logged" '-A INPUT -p tcp --dport microsoft-ds -j DROP'
FWboth "dropping common hack target, not logged" '-A INPUT -p tcp --dport ms-sql-s -j DROP'
FWboth "log-dropping input at end of chain" '-A INPUT -j log-drop'


if [ -x /usr/sbin/dpkg-reconfigure ]; then
   if [ -x /usr/bin/fail2ban-server ]; then
      dpkg-reconfigure fail2ban
   fi
fi

$ECHO "I: update INPUT policy to DROP"
#FWboth "" -P INPUT DROP
#FW4 "" -P INPUT DROP
FW4 "" -P INPUT ACCEPT

#$ECHO "I: adding blacklist from http://mirror.ip-projects.de/ip-blacklist"
#$IPTABLES -t blacklist_ip_projects_de -F || $ECHO "[ignored]"
#$IPTABLES -t blacklist_ip_projects_de -X || $ECHO "[ignored]"
#$IPTABLES -N blacklist_ip_projects_de 
#$WGET -O - http://mirror.ip-projects.de/ip-blacklist |$SORT|$XARGS -n1 $IPTABLES -A blacklist_ip_projects_de -j DROP -s
#$IPTABLES -I INPUT -j blacklist_ip_projects_de
#
#$ECHO "I: adding blacklist from openbl.org - takes some minutes"
#$IPTABLES -t blacklist_openbl_org -F || $ECHO "[ignored]"
#$IPTABLES -t blacklist_openbl_org -X || $ECHO "[ignored]"
#$IPTABLES -N blacklist_openbl_org
#$WGET -O - http://www.openbl.org/lists/base.txt.gz|gunzip -dc | $EGREP '^[0-9]' |$SORT|$XARGS -n1 $IPTABLES -A blacklist_openbl_org -j DROP -s
#$IPTABLES -I INPUT -j blacklist_openbl_org

if [ "yes" = "$ThisIsGateway" ]; then
	$ECHO "I: NAT"
	if $IFCONFIG | $GREP -q eth0.102; then
		FW4 "Directing 10.135.0.0/16 to the internet." '-t nat -A POSTROUTING -s 10.135.0.0/16 -o eth0.101 -j MASQUERADE'
		#FW4 "Directing 192.168.186.0/24 o the internet." '-t nat -A POSTROUTING -s 192.168.186.0/24 -o eth0.101 ! -d 192.168.178.0/24 -j MASQUERADE'
		FW4 "Directing 192.168.186.0/24 o the internet." '-t nat -A POSTROUTING -s 192.168.186.0/24 -o eth0.101 -j MASQUERADE'
	else
		FW4 "Directing 10.135.0.0/16 leaving to the internet." '-t nat -A POSTROUTING -s 10.135.0.0/16 -o eth0 -j MASQUERADE'
	fi
	if $IFCONFIG | $GREP -q mullvad; then
		FW4 "Routing 10.135.0.0/16 anonymously through mullvad." '-t nat -A POSTROUTING -s 10.135.0.0/16 -o mullvad -j MASQUERADE'
		if $IFCONFIG | $GREP -q eth0.102; then
			FW4 "Routing 192.168.0.0/16 anonymously through mullvad." '-t nat -A POSTROUTING -s 192.168.0.0/16 -o mullvad -j MASQUERADE'
		else
		fi


		anonymizer=$($IP route |$GREP mullvad | $AWK '{print $9}')
		if [ "" = "$anonymizer" ]; then
			$ECHO "E: Could not determine IP to Mullvad OpenVPN - restart that"
			exit 1
		fi
		$IP route replace default via $anonymizer table freifunk

		if ifconfig mullvad | grep -q inet6; then 
			echo "I: Found IPv6 address for mullvad - also anynymizing that"
			FW6 "Routing IPv6 anonymously through mullvad" -t nat -A POSTROUTING -s fd73:111:e824::2:1/64 ! -d fd73:111:e824::2:1/64 -o mullvad -j MASQUERADE
		else
			echo "I: No IPv6 address for mullvad"
		fi
	fi
	$ECHO "[OK]"
else
	$ECHO "I: Skipping NAT since not a gateway"
fi

#$IPTABLES -L -n
#ip6tables -L -n


#Stopped blocking upfront
## Allow dedicated  ICMPv6 packettypes, do this in an extra chain because we need it everywhere
FW6 " " "-N AllowICMPs"
FW6 "Destination unreachable" "-A AllowICMPs -p icmpv6 --icmpv6-type 1 -j ACCEPT"
FW6 "Packet too big" "-A AllowICMPs -p icmpv6 --icmpv6-type 2 -j ACCEPT"
FW6 "Time exceeded" "-A AllowICMPs -p icmpv6 --icmpv6-type 3 -j ACCEPT"
FW6 "Parameter problem" "-A AllowICMPs -p icmpv6 --icmpv6-type 4 -j ACCEPT"
FW6 "Echo Request (protect against flood)" "-A AllowICMPs -p icmpv6 --icmpv6-type 128 -m limit --limit 5/sec --limit-burst 10 -j ACCEPT"
FW6 "Echo Reply" "-A AllowICMPs -p icmpv6 --icmpv6-type 129 -j ACCEPT"
