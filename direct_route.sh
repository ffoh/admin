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
ad.doubleclick.net
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
plus.google.com
talkgadget.google.com
# spiegel - start
spiegel.de
www.spiegel.de
spiegel.de
cdn1.spiegel.de
cdn2.spiegel.de
cdn3.spiegel.de
cdn4.spiegel.de
magazin.spiegel.de
spiegel.ivwbox.de
c.spiegel.de
dc59.s290.meetrics.net
dc61.s290.meetrics.net
geschichte.spiegel.de
plusone.google.com
s290.mxcdn.net
# spiegel - end
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
# ARD mit Tagesschau - start
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
programm.ard.de
www.sportschau.de
www1.sportschau.de
wmswr-lh.akamaihd.net
79423.analytics.edgesuite.net
wmswr-lh.akamaihd.net
ma140-r.analytics.edgesuite.net
www1.wdr.de
# ARD mit Tagesschau - end
www.ardmediathek.de
cp229098.edgefcs.net
script.ioam.de
# NRD - start
ndr.de
ndr.ivwbox.de
ndr_fs-lh.akamaidhd.net
www.n-joy.de
www.ndr.de
www.hr.gl-systemhaus.de
www.eurovision.de
players.edgesuite.net
hds.ndr.de
de.ioam.de
# NDR - end
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
# BR - start
bronline.de
bralpha.de
br.de
bronline.ivwbox.de
cdn-vod-hds.br.de
www.edgesuite.net
79423.analytics.edgesuite.net
ma140-r.analytics.edgesuite.net
www.br.de
players.edgesuite.net
www.bronline.de
livestreams.br.de
# BR - end
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
# Radio
rsh.de
www.rsh.de
ajax.googleapis.com
bam.nr-data.net
content.rsh.de
i1.ytimg.com
newscloud.fm
rsh.ivwbox.de
rum-collector.pingdom.net
rum-static.pingdom.net
s.ytimg.com
i1.ytimg.com
deltaradio.de
www.deltaradio.de
content.deltaradio.de
deltarad.ivwbox.de
ecx.images-amazon.com
media1.deltaradio.de
media2.deltaradio.de
media3.deltaradio.de
media4.deltaradio.de
media5.deltaradio.de
qs.ioam.de
qs.ivwbox.de
livestream.deltaradio.de
streams.deltaradio.de
deltarad.ivwbox.de
# Radio - end
# TED - start
www.ted.com
assets2.tedcdn.com
img.tedcdn.com
metrics.ted.com
b.scorecardresearch.com
# TED - end
webmail.uksh.de
www.uni-luebeck.de
webmail.uk-sh.de
www.uksh.de
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
