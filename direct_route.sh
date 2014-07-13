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

IPs=$(cat <<EOIPS | grep -v ^#
#
ostholstein.freifunk.net
gw1.ostholstein.freifunk.net
gw2.ostholstein.freifunk.net
# much sought after
de.sitestat.com
# 
google-public-dns-a.google.com
www.google.com
google.com
google.de
www.google.de
apis.google.de
www.google-analytics.com
mail.google.com
gmail.com
spiegel.de
www.spiegel.de
cdn1.spiegel.de
cdn2.spiegel.de
cdn3.spiegel.de
cdn4.spiegel.de
magazin.spiegel.de
spiegel.ivwbox.de
c.spiegel.de
spotify.com
www.spotify.com
# Arte - begin
arte.tv
info.arte.tv
future.arte.tv
creative.arte.tv
concert.arte.tv
cinema.arte.tv
www.arte.tv
reports.cedexis.com
org-www.arte.tv
probes.cedexis.com
probe.cedexis.org
eu-ems1.joyent.bench.cedexis.com
www.googleapis.com
client1.google.com
radar.cedexis.com
llnwop-eu.cedexis.com
llnwop.cedexis.com
cedexis.cdn.mediactive-network.net
sjc2.voxcloud.cedexis.com
dca.sl.bench.cedexis.com
ecadn-eu.cedexis.com
logi104.xiti.com
videos.arte.tv
fonts.googleapis.com
connect.facebook.net
www.googletagmanager.com
graph.facebook.com
www-secure.arte.tv
limelight.cedexis.com
wac.799d.i1.cdndelivery.com
artestras.vo.llnwd.net
p.jwpcdn.com
level3.cedexis.com
logs1136.xiti.com
fastlydsa.bench.cedexis.com
playout.3qsdn.com
c3de.wpc.azureedge.net
ak.c.ooyala.com
az315059.vo.msecnd.net
cdn.api.twitter.com
cedexis.gccdn.net
cs600.wac.edgecastcdn.net
gb2.cedexis.swiftserve.com
hcacheg.tdf-cdn.com
logc136.xiti.com
anycast.cedexis.com
cedexis-test01.insnw.net
cedexis.a.cdnify.io
cloudfront-dsa.cedexis.com
i1-js-14-3-01-10106-780860262-i.init.cedexis-radar.net
sita-atl.bench.cedexis.com
cedexis2.cachefly.net
cds.z5t8n6p8.hwcdn.net
a.disquscdn.com
b.scorecardresearch.com
go.disqus.com
cloud.typography.com
# Arte - end
ebay.de
www.ebay.de
# RBB - start
www.rbb-online.de
rbb-online.de
mediathek.rbb-online.de
rbb.ivwbox.de
rbb.ic.llnwd.net
# RBB - end
# Tagesschau - start
tagesschau.de
www.tagesschau.de
ard.de
www.ard.de
www.sportschau.de
ardsport.ivwbox.de
gsea.ivwbox.de
swr.ivwbox.de
adaptiv.wdr.de
ard.ivwbox.de
logi242.xiti.com
tagessch.ivwbox.de
media.tagesschau.de
# Tagesschau - end
www.ardmediathek.de
cp229098.edgefcs.net
script.ioam.de
ndr.de
ndr.ivwbox.de
ndr_fs-lh.akamaidhd.net
www.ndr.de
www.hr.gl-systemhaus.de
www.eurovision.de
players.edgesuite.net
hds.ndr.de
de.ioam.de
spotify.com
www.spotify.com
ftp.de.debian.org
anonscm.debian.org
alioth.debian.org
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
freshmeat.net
bronline.de
bralpha.de
br.de
bronline.ivwbox.de
cdn-vod-hds.br.de
www.edgesuite.net
79423.analytics.edgesuite.net
ma140-r.analytics.edgesuite.net
#
phoenix.de
www.phoenix.de
# ZDF - start
webcam.zdf.de
wwwdyn.zdf.de
phoenix.ivwbox.de
fstreaming.zdf.de
secure-eu.imrworldwide.com
zdf_hds_de-f.akamaihd.net
zdf.de
www.zdf.de
zdf_hds_de-f.akamaihd.net
79423.analytics.edgesuite.net
code.etracker.com
de.ioam.de
fstreaming.zdf.de
ma140-r.analytics.edgesuite.net
module.zdf.de
secure-eu.imrworldwide.com
sofa01.zdf.de
vqm.zdf.de
www.etracker.de
www.zdf.de
# ZDF - end
EOIPS
)

for n in $IPs
do
	echo "$n"
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
			ipdirect $IP
		done
	fi
done
