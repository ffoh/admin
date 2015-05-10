#!/bin/bash

set -e

gateway=$(LANG=C ifconfig eth0 | grep "inet addr" |cut -f2 -d:|cut -f1 -d\ )

if [ -z "$gateway" ]; then
	echo "E: Could not identify gateway via ifconfig eth0"
	exit 1
fi
echo -n "Identified gateway as '$gateway'"

via=$(echo $gateway|cut -f 1,2,3 -d .).1

if [ -z "$via" -o ".1" = "$via" ]; then
	echo
	echo "E: Could not determine router through which to exit - yielded '$via'"
	exit 1
fi

echo " routing via '$via'"

anomizer=$(LANG=C ifconfig mullvad | grep "inet addr" |cut -f2 -d:|cut -f1 -d\ )
echo "Anonmizer is $anomizer"
if [ -z "$anomizer" ]; then
	echo "E: Could not determine IP of anonymizer."
	exit 1
fi
echo "Resetting anonymizer to route via '$anomizer'"
ip route replace default via $anomizer table freifunk
ip route replace 0.0.0.0/1 via $anomizer table freifunk
ip route replace 128.0.0.0/1 via $anomizer table freifunk

function ipdirect () {
	ip=$1
	#if ! ip route list table freifunk | grep -q "$ip"; then
	if ! ip route get $ip from 10.135.8.100 iif bat0 | grep -q eth0; then
		echo "I: Adding route for $ip via $via for table freifunk"
		ip route replace $ip via $via table freifunk
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

IPs=$(cat <<EOIPS | grep -v ^# |cut -f1|sort -u
#
ostholstein.freifunk.net
luebeck.freifunk.net
www.freifunk.net
gw1.ostholstein.freifunk.net
gw2.ostholstein.freifunk.net
#de.sitestat.com
#wildcard.sitestat.com	# intentionally anonymised, bahn.de
www.apple.com	# not redundant
17.0.0.0/8	appstore.com www.appstore.com swdlp.apple.com # apple service addresses 
173.194.0.0/16	accounts.google.com accounts.google.com ad.doubleclick.net apis.google.de apis.google.de csi.gstatic.com gmail.com gmail.com googleads.g.doubleclick.net google.com google.com gstatic.com id.google.de mail.google.com mail.google.com maps.gstatic.com oauth.googleusercontent.com plus.google.com plus.google.com plusone.google.com plusone.google.com ssl.gstatic.com talkgadget.google.com talkgadget.google.com www.googleadservices.com www.google-analytics.com www.googletagmanager.com www.gstatic.com youtube.com ssl.google-analytics.com mt0.googleapis.com mt1.googleapis.com maps.google.com maps.google.de mt0.google.com lh3.googleusercontent.com fonts.gstatic.com maps.gstatic.com
216.58.192.0/19	maps.googleapis.com
98.136.0.0/14	yahoo.com
141.83.0.0/16	uni-luebeck.de
134.245.0.0/16	uni-kiel.de 134.245
134.246.0.0/15	uni-kiel.de 134.24[67]
193.155.127.0/25	samsung 193.155.127.0 - 193.155.127.127
74.125.0.0/16	ajax.googleapis.com fonts.googleapis.com # google
173.194.0.0/16	ssl.gstatic.com # google
81.26.166.0/24	i.ligatus.com d.ligatus.com
141.76.0.0/16	ftp.de.debian.org # Uni Dresden
132.2.0.0/16	mailserv01.uni-tuebingen.de # Uni Tuebingen
#s.youtube.com	redundant
#www.youtube.com	redundant
#www.youtube-nocookie.com	redundant
# 
8.8.8.8	google-public-dns-a.google.com
8.8.4.4	google-public-dns-b.google.com
74.125.0.0/16	id.google.de
oauth.googleusercontent.com
144.15.0.0/16	carelink.minimed.com medtronic.com
# Facebook - start
connect.facebook.net
173.252.64.0/18	apps.facebook.com graph.facebook.com # facebook
173.252.64.0/18	facebook
31.13.109.0/24	facebook
69.171.224.0/19	facebook
31.13.100.0/24	facebook
31.13.93.0/24	facebook
static.ak.facebook.com
s-static.ak.facebook.com
# Facebook - end
# spiegel - start
ad2.adfarm1.adition.com
adserv.quality-channel.de
cdn1.spiegel.de
cdn2.spiegel.de
cdn3.spiegel.de
cdn4.spiegel.de
cdn.api.twitter.com
count.spiegel.de
c.spiegel.de
dc44.s290.meetrics.net
dc59.s290.meetrics.net
dc60.s290.meetrics.net
dc61.s290.meetrics.net
dc72.s290.meetrics.net
dc72.s290.meetrics.net
geschichte.spiegel.de
magazin.spiegel.de
m.spiegel.de
plusone.google.com
qs.ioam.de
qs.ivwbox.de
s290.mxcdn.net
script.ioam.de
spiegel.de
spiegel.ivwbox.de
199.16.156.0/22	twitter.com analytics.twitter.com syndication.twitter.com
platform.twitter.com	# not redundant
video2.spiegel.de
video.spiegel.de
vt.adition.com
www.google-analytics.com
www.spiegel.de
imagesrv.adition.com
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
www.googletagmanager.com
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
cdn.api.twitter.com	# not redundant
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
# ebay - start
ebay.de
www.ebay.de
www.ebay.com
cgi.ebay.com
api.ebay.com
open.api.ebay.com
mobior.ebay.com
mobidcs.ebay.com
rpsx.ebay.com
ebay.ivwbox.de
kleinanzeigen.ebay.de
static.criteo.net
widget.criteo.com
ir.ebaystatic.com
p.ebaystatic.com
q.ebaystatic.com
pages.ebay.de
pics.ebaystatic.com
rover.ebay.de
rtm.ebaystatic.com
i.ebayimg.com
svcs.ebay.com
thumbs.ebaystatic.com
thumbs1.ebaystatic.com
thumbs2.ebaystatic.com
thumbs3.ebaystatic.com
thumbs4.ebaystatic.com
vi.vipr.ebaydesc.com
www.sainsmart.com
i18.ebayimg.com
# ebay - end
# paypal - start
www.paypal.de
www.paypal.com
www.paypalobjects.com
paypal.d1.sc.omtrdc.net
t.paypal.com
paypal.de
b.stats.paypal.com
altfarm.mediaplex.com
# paypal - end
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
liveupdate1.scribblelive.com
counter.scribblelive.com
love.scribblelive.com
cdn-storage.br.de
media.ndr.de
download.media.tagesschau.de
www.mdr.de
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
www.debian.org
www.ubuntu.com
canonical.com
zatoo.com
www.zatoo.com
# amazon - start
amazon.de
cloudfront-labs.amazonaws.com
ecx.images-amazon.com
fls-devo.vipinteg.amazon.com
fls-eu.amazon.de
g-ecx.images-amazon.com
g-ec2.images-amazon.com
images-na.ssl-images-amazon.com
static.amazon.de
www.amazon.de
z-ecx.images-amazon.com
images-na.ssl-images-amazon.com
cloudfront-labs.amazonaws.com
atv-ps-eu.amazon.com
smooth.l3.cdn.lovefilm.com
# amazon - end
volksbank-luebeck.de
www.volksbank-luebeck.de
volksbank-eutin.de
www.volksbank-eutin.de
192.30.252.0/22	github.com
last.fm
www.last.fm
lastfm.de
www.lastfm.de
google-analytics.com
www.google-analytics.com
# GMX - start
gmx.de
gmx.net
www.gmx.de
www.gmx.net
pop.gmx.net
hsp.gmx.net
mail.gmx.net
suche.gmx.net
navigator.gmx.net
s3.amazonaws.com
fbcdn-profile-a.akamaihd.net
i0.gmx.net
s.uicdn.com
gmx.ivwbox.de
s.uicdn.com
uim.tifbs.net
img.ui-portal.de
info.gmx.net
wa.ui-portal.de
px.wa.ui-portal.de
s.uicdn.com
js.ui-portal.de
trackbar.navigator.gmx.net
home.navigator.gmx.net
3c.gmx.net
cdn.gmxpro.net
hsp-bap.gmx.net
uas2-bap.gmx.net
# GMX Werbung
adclient.uimserv.net
pixelbox.uimserv.net
uidbox.uimserv.net
# GMX - end
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
sportstudio.zdf.de
secure-eu.imrworldwide.com
79423.analytics.edgesuite.net
ma140-r.analytics.edgesuite.net
vqm.zdf.de
fgeostreaming.zdf.de
cp125302.edgefcs.net
2df.ivwbox.de
heute.ivwbox.de
www.etracker.de
code.etracker.com
# ZDF - end
# HR - start
www.hr-online.de
www.hr.gl-systemhaus.de
logi104.xiti.com
hr.ivwbox.de
# HR - end
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
193.174.0.0/15	webmail.uksh.de webmail.uk-sh.de www.uksh.de # DFN
194.94.0.0/15	embl.de # DFN
141.22.0.0/16	haw-hamburg.de # DFN
# OOKLA Speedtest - start
www.speedtest.net
c.speedtest.net
a.adroll.com
a.c.appier.net
ads.ookla.com
c.betrad.com
cse.google.com
fast.wistia.net
zdbb.net
cdn.static.zdbb.net
walker.zdbb.net
pipedream.wistia.com
distillery.wistia.com
by.uservoice.com
cdn.ads.ookla.com
cdn.optimizely.com
cm.g.doubleclick.net
d.adroll.com
googleads.g.doubleclick.net
ib.adnxs.com
ih.adscale.de
sadmin.brightcove.com
match.adsrvr.org
pagead2.googlesyndication.com
pixel.quantserve.com
pubads.g.doubleclick.net
px.adhigh.net
sl-02.wemacom.de
speedtest.csb-net.de
speedtest.studiofunk.de
speedtest.swnnms.net
speedtest.wtnet.de
us-u.openx.net
view.atdmt.com
www.google-analytics.com
tiles.cdnst.net
# OOKLA Speedtest - end
108.160.160.0/20	dropbox.com
www.amung.us
amung.us
# web.de - start
pop3.web.de
imap.web.de
navigator.web.de
hsp.web.de
www.web.de
web.de
home.navigator.web.de
3c.web.de
webdessl.ivwbox.de
freemail.web.de
img.web.de
smtp.web.de
# web.de - end
91.198.174.0/24	de.wikipedia.org commons.wikimedia.org wikimedia.org bits.wikimedia.org login.wikimedia.org upload.wikimedia.org meta.wikimedia.org www.wikimedia.org	Wikimedia Europe
# T-online - start
194.25.134.0/24	email01.t-online.de mail.t-online.de
62.153.158.0/23	www.t-online.de bilder.t-online.de img.toi.de dlc2.t-online.de login.idm.telekom.com stats.t-online.de # 62.153.158.0 - 62.153.159.255 
217.6.164.0/22	www.t-online.de bilder.t-online.de dlc2.t-online.de stats.t-online.de # 217.6.164.0 - 217.6.167.255
62.157.140.0/23	tipi.api.t-online.de # 62.157.140.0 - 62.157.141.255
80.156.84.0/22	p.toi.de p.t-online.de sportdaten.t-online.de tcmt.t-online.de mailing.fs.t-online.de s1.fs.t-online.de # 80.156.84.0 - 80.156.87.255
homad-global-configs.schneevonmorgen.com
#img.community.t-online.de	# not redundant - community site, bewusst nicht deanonymisiert
s0.2mdn.net
cj.madeleine.de
dcs.netbiscuits.net
logs1204.xiti.com
toi-ssl.ivwbox.de
sv.sheego.de
toi.ivwbox.de
logc205.xiti.com
adclear.teufel.de
cj.peterhahn.de
s2.fs.t-online.de
logc206.xiti.com
accounts.login.idm.telekom.com
www.wetter.info
gfk-de.sensic.net
# T-online - end
# ORF - start
orf.at
www.orf.at
# ORF - end
webtrends.de
scs.webtrends.de
mittelstein.de
mail.mittelstein.de
mapandroute.de
www.mapandroute.de
www1.mapandroute.de
www2.mapandroute.de
osm0.mapandroute.de
osm1.mapandroute.de
osm2.mapandroute.de
osm3.mapandroute.de
iw.mapandroute.de
themes.googleusercontent.com
www.norges-bank.no
statse.webtrendslive.com
www.nbim.no
www.me.com
mail.me.com
www.openstreetmap.org
piwi.openstreetmap.org
nominatim.openstreetmap.org
a.tile.openstreetmap.org
b.tile.openstreetmap.org
c.tile.openstreetmap.org
www.gravatar.com
i0.wp.com
i1.wp.com
dev.virtualearth.net
ecn.t0.tiles.virtualearth.net
ecn.t1.tiles.virtualearth.net
ecn.t2.tiles.virtualearth.net
ecn.t3.tiles.virtualearth.net
a.tiles.mapbox.com
b.tiles.mapbox.com
c.tiles.mapbox.com
# RTL - start
217.118.168.0/22	RTL interactive Frankfurt
#hds.webclips.fra.rtl.de	# redundant
bilder.static-fra.de
cdn.static-fra.de
#www.rtl.de		# redundant
static.plista.com
#autoimg.rtl.de		# redundant
autoimg.static-fra.de
bilder.akamai.rtl.de
fbcdn-profile-a.akamaihd.net
px1.vtrtl.de
#bilder.rtl.de		# redundant
qs.ivwbox.de
#count.rtl.de		# redundant
rtl.ivwbox.de
static.plista.com
#tracking.rtl.de	# redundant
# RLT - end
# SAT1 - start
www.sat1.de
epg.kabeleins.de
ad.71i.de
common-st.p7s1digital.de
epg.sat1.de
www.googletagservices.com
static.chartbeat.com
script.ioam.de
service.maxymiser.net
common-st.p7s1digital.de
fbcdn-profile-a.akamaihd.net
scontent-b.xx.fbcdn.net
ping.chartbeat.net
sat1.ivwbox.de
sat101.webtrekk.net
stats.g.doubleclick.net
psdvodhdsdrm.dcp.adaptive.level3.net
is.myvideo.de
fbstatic-a.akamaihd.net
livepassdl.conviva.com
thumbnails.sevenoneintermedia.de
oauth.googleusercontent.com
rec.sat1.de
getdetails02.sim-technik.de
ivwextern.sat1.de
vas.sim-technik.de
# SAT1 - end
# PRO7 - start
www.prosieben.de
ds.serving-sys.com
ad.71i.de
thumbnails.sevenoneintermedia.de
service.maxymiser.net
ad.de.doubleclick.net
pubads.g.doubleclick.net
adserver.71i.de
s1.adform.net
cdn.krxd.net
thumbnails.sevenoneintermedia.de
pro7.ivwbox.de
ds.serving-sys.com
rec3.prosieben.de
t.prosieben.de
rec.prosieben.de
# PRO7 - end
# Kabel1 - start
kabel1.ivwbox.de
www.kabeleins.de
fbcdn-profile-a.akamaihd.net
static.chartbeat.com
rec.kabeleins.de
qs.ivwbox.de
qs.ioam.de
thumbnails.sevenoneintermedia.de
epg.kabeleins.de
pagead2.googlesyndication.com
cdn.flashtalking.com
servedby.flashtalking.com
ivwextern.kabeleins.de
# Kabel1 - end
imap.1und1.de
smtp.1und1.de
pop.1und1.de
# booking.com, villas.com - start
iphone-xml-l.booking.com
www.booking.com
secure.booking.com
q.bstatic.com
r.bstatic.com
gi.bttlcheck.com
am-img.agoda.net
eprofile.uimserv.net
dis.criteo.com
ads.adtiger.de
pixel.rubiconproject.com
ads.yahoo.com
image2.pubmatic.com
x.bidswitch.net
dis.eu.criteo.com
bat.bing.com
bat.r.msn.com
widget.criteo.com
plick.yahoo.com
tracking.smartstream.tv
www.villas.com
t-ec.vcomstatic.com
ads.smartstream.tv
# booking.com, villas.com - end
hrs.de
www.hrs.de
www.albamoda.de
# NTP - start
alvo.fungus.at
arthur.testserver.li
ashe.besaid.de
bytesink.de
callisto.mysnip.de
cse-server.com
donotuse.de
fabiangruber.de
frankfurt1.firstlinknetworks.com
golem.canonical.com
juniperberry.canonical.com
license.aimms.com
mail.elfert.de
mokujin.gionn.net
netz.smurf.noris.de
ns1.blazing.de
ns1.bvc-cloud.de
ns1.newsnet.li
ns2.customer-resolver.net
ntp1.linuxhosted.ca
public.streikt.net
public.trexler.at
pyxis.my-rz.de
s1.kelker.info
smtp01.it-wagenbrenner.de
static.140.107.46.78.clients.your-server.de
stratum2-3.NTP.TechFak.NET
stratum2-3.NTP.TechFak.Uni-Bielefeld.de
stratum2-4.NTP.TechFak.Uni-Bielefeld.de
stratum2-4.NTP.TechFak.Uni-Bielefeld.de
test.danzuck.ch
triton916.startdedicated.de
wotan.tuxli.ch
# NTP - end
# Zatoo - start
adtech-ads-shared-frr.evip.aol.com
92.122.214.0/24	Akamai
91.123.100.0/24 Zatoo
# Zatoo - end
# NIST Internet Time Servers - start
time-a.nist.gov
time-b.nist.gov
time-c.nist.gov
time-d.nist.gov
nist1-ny.ustiming.org
nist1-nj.ustiming.org
nist1-nj2.ustiming.org
nist1-ny2.ustiming.org
nist1-pa.ustiming.org
nist1.aol-va.symmetricom.com
nist1-macon.macon.ga.us
nist1-atl.ustiming.org
wolfnisttime.com
nist1-chi.ustiming.org
nist.time.nosc.us
nist.expertsmi.com
nist.netservicesgroup.com
nisttime.carsoncity.k12.mi.us
nist1-lnk.binary.net
wwv.nist.gov
time-nist.symmetricom.com
time-a.timefreq.bldrdoc.gov
time-b.timefreq.bldrdoc.gov
time-c.timefreq.bldrdoc.gov
# NIST Internet Time Servers - end
# Welt.de - start
cdn.cxense.com
cdn.flashtalking.com
cdn4.emediate.eu
www.welt.de
ww251.smartadserver.com
static.chartbeat.com
cdn.krxd.net
static.plista.com
farm.plista.com
iconist.de
js.revsci.net
wetter.welt.de
pix04.revsci.net
ads.heias.com
servedby.flashtalking.com
apiservices.krxd.net
load.s3.amazonaws.com
comcluster.cxense.com
welt.ivwbox.de
# Welt.de - end
# Sky.com - start
198.63.0.0/16	liveperson.net
198.64.0.0/15	liveperson.net
198.66.0.0/16	liveperson.net
ad.doubleclick.net
ad-emea.doubleclick.net
ad.yieldlab.net
admin.brightcove.com
amv3-tslogging.touchcommerce.com
api.adrtx.net
api.bizographics.com
www.skygo.sky.de
80.238.27.0/24	# Sky Broadcasting
90.192.0.0/11	# BSkyB
assets.adobedtm.com
sky.de.d3.sc.omtrdc.net
skygo.sky.de
dpm.demdex.net
www.microsoft.com
go.sky.com
livepassdl.conviva.com
gwb.lphbs.com
79423.analytics.edgesuite.net
sky.de.d3.sc.omtrdc.net
ma100-r.analytics.edgekey.net
apiservices.krxd.net
assets.sky.com
asv.nuggad.net
beacon.krxd.net
britishskybroadcasti.tt.omtrdc.net
www.skygo.sky.de
skygo.sky.de
b.scorecardresearch.com
cdn1.smartadserver.com
cdn.adrtx.net
cdn.krxd.net
cm.g.doubleclick.net
d2oh4tlt9mrke9.cloudfront.net
dis.criteo.com
eas.apm.emediate.eu
ecustomeropinions.com
epgstatic.sky.com
skymovies.sky.com
epgservices.sky.com
m.webtrends.com
skyid.sky.com
fbstatic-a.akamaihd.net
go.affec.tv
googleads.g.doubleclick.net
ib.adnxs.com
i.ctnsnet.com
id.impressiondesk.com
js.revsci.net
loadm.exelator.com
metrics.sky.com
my.sky.com
omni.sky.de
ds-aksb-a.akamaihd.net
1.s10i.com
p2.s10i.com
pix04.revsci.net
pixel.mathtag.com
pixel.quantserve.com
pix.impdesk.com
rtax.criteo.com
rtt.adrolays.de
sales.liveperson.net
sd.nakamitech.de
secure.adnxs.com
server.lon.liveperson.net
service.maxymiser.net
skyde.inq.com
skystorage-a.akamaihd.net
smetrics.sky.com
sr2.liveperson.net
storage.sky.com
t13.intelliad.de
t23.intelliad.de
t.mookie1.com
ws.sessioncam.com
ww251.smartadserver.com
www.sky.com
premiede.ivwbox.de
api.brightcove.com
qs.ivwbox.de
skydeutschland.edgesuite.net
brightcove.vo.llnwd.net
ced.sascdn.com
gmads.net
cdn1.smartadserver.com
ak-ns.sascdn.com
audienceinsights.net
c.brightcove.com
metrics.brightcove.com
goku.brightcove.com
skydeutschland.pd.ak.o.brightcove.com.edgesuite.net
# Sky.com - end
b.medtronic.com	# not redundant, pointing to adobe
# Java - start
java.com
oracle.112.2o7.net
javadl.sun.com
sdlc-esd.sun.com
# Java - end
# Ryanair - start
www.ryanair.com
metrics.ryanair.com
cdnjs.cloudflare.com
www.bookryanair.com
smetrics.ryanair.com
ajax.googleapis.com
code.jquery.com
# Ryanair - end
www.flughafen-luebeck.de
bilder.static-fra.de
mapwidget.11880.com
count.rtl.de
www.wetter.de
# 
i1.ytimg.com
gg.google.com
yt3.ggpht.com
lh4.ggpht.com
www.comdirect.de
charts.comdirect.de
kunde.comdirect.de
# marksetwatch - start
www.marketwatch.com
mw1.wsj.net
mw2.wsj.net
mw3.wsj.net
mw4.wsj.net
s.wsj.net
i.marketwatch.com
widgets.outbrain.com
odb.outbrain.com
i.mktw.net
i.marketwatch.com
s.marketwatch.com
tags.tiqcdn.com
images.outbrain.com
b.scorecardresearch.com
mwstream.wsj.net
djibeacon.dowjoneson.com
mwstream.wsj.net
sc.wsj.net
sj.wsj.net
zor.fyre.com
platform.linkedin.com
js.bankrate.com
www.linkedin.com
i.ytimg.com
ei.marketwatch.com
bootstrap.marketwatch.fyre.co
partnerservices.bankrate.com
bit.ly
m.wsj.net
cdn.livefyre.com
gravatar.com
cm.g.doubleclick.net
om.dowjoneson.com
api.wsj.net
si4.s.dev.wsj.com
# marksetwatch - end
# LN - start
www.ln-online.de
lnonl.ivwbox.de
api.brightcove.com
api.brightcove.com
media.ln-online.de
code.etracker.com
cdn-media.ln-und-oz.de
markt.ln-online.de
ostseezt.ivwbox.de
www.dhd24.com
static-dhd24.dhd.de
images0.dhd.de
images1.dhd.de
images2.dhd.de
images3.dhd.de
images4.dhd.de
script.ioam.de
dhd24.ivwbox.de
# LN - end
# ADAC - start
www.adac.de
webts.adac.de
service.maxymiser.net
routenplaner.adac.de
www.marinafuehrer.adac.de
stats.vektorrausch.de
themes.googleusercontent.com
fonts.googleapis.com
www.windfinder.com
# ADAC - end
www.timmendorfer-strand.org
www.niendorf-ostsee.de
niendorf2014.avisto.eu
www.buchen.travel
z1.im-web.de
images.im-web.de
visitenkarten.im-web.de
ajax.googleapis.com
# facebook spiel - start
173.244.184.34
plarium.hs.llnwd.net
173.244.184.114
6-channel-proxy-07-ash2.facebook.com
fbexternal-a.akamaihd.net
s-assets.tp-cdn.com
fbcdn-profile-a.akamaihd.net
pixel.facebook.com
totaldomination.x-plarium.com
fbstatic-a.akamaihd.net
fbcdn-photos-g-a.akamaihd.net
fbcdn-photos-b-a.akamaihd.net
fbcdn-photos-a-a.akamaihd.net
fbcdn-profile-a.akamaihd.net
cluster-3.skillclub.com
fbexternal-a.akamaihd.net
# facebook spiel - end
# Apple TV - start
361250524.log.optimizely.com
securemetrics.apple.com 66.235.135.144
store.storeimages.cdn-apple.com
store.apple.com
metrics.apple.com
itunes.apple.com
images.apple.com
tw.appstore.com
a248.e.akamai.net
s.mzstatic.com
ssl.apple.com
a1.mzstatic.com
a2.mzstatic.com
a3.mzstatic.com
a4.mzstatic.com
a5.mzstatic.com
fbcdn-profile-a.akamaihd.net
ax.itunes.apple.com
# Apple TV - end
# Westfaelische Nachrichten - start
www.wn.de
api.brightcove.com
admin.brightcove.com
c.brightcove.com
static.wn.de
cdn.nativendo.de
www.energiefreiheit.com
static.plista.com
farm.plista.com
cdn.taboola.com
images.taboola.com
trc.taboola.com
rub-media.westfaelische-nachrichten.de
event.yoochoose.net
cdn.taboolasyndication.com
westnach.ivwbox.de
static2.wn.de
qs.ioam.de
de.ioam.de
# Westfaelische Nachrichten - end
# stepstone - start
stepston.ivwbox.de
www.stepstone.de
media.stepstone.com
stepstone.112.2o7.net
b.scorecardresearch.com
qc.stepstone.de
qc-de.stepstone.com
# stepstone - end
# slashdot.org - start
stats.dice.com
slashdot.org
widget-cdn.rpxnow.com
slashdot.org
mx.sourceforge.net
sourceforge.net
politics.slashdot.org
# slashdot.org - end
# FAZ - start
ping.chartbeat.net
farm.plista.com
193.227.144.0/20	www.FAZ.net media0.faz.net media1.faz.net
faz.ivwbox.de
rce.veeseo.com
apis.google.com
cdn.api.twitter.com
pbs.twimg.com
faz.met.vgwort.de
# FAZ - end
204.69.221.0/24	tunein.com services.radiotime.com
# POPCAP - start
199.36.252.0/22	popcap draper.popcap.com popcap.com
static-www.ecs.popcap.com	# not redundant
fbexternal-a.akamaihd.net
pvza-production.popcapsf.com
0-channel-proxy-06-frc1.facebook.com
# POPCAP - end
imap.mail.de
api.flattr.com
# wetter.com - start
wetter.com
s7.addthis.com
dev.visualwebsiteoptimizer.com
wetter.ivwbox.de
www.wetter.com
m.addthis.com
static.chartbeat.com
ping.chartbeat.net
ls1.wettercomassets.com
ls2.wettercomassets.com
m1.wettercomassets.com
js.api.here.com
# wetter.com - end
# livespotting.tv - start
stream.livespotting.tv
player.livespotting.tv
piwik.windit.de
cdnjs.cloudflare.com
# livespotting.tv - end
# reichelt - start
www.reichelt.de
css.cdn-reichelt.de
js.cdn-reichelt.de
cdn-reichelt.de
statistic2.reichelt.de
css.cdn-reichelt.de
cdn.exactag.com
rwt.reichelt.de
m.exactag.com
t.flix360.com
media.flixcar.com
# reichelt - end
# Wetter.de - start
cdn.static-fra.de
www.wetter.de
bilder.rtl.de
rtl.ivwbox.de
count.rtl.de
autoimg.rtl.de
# Wetter.de - end
imagesrv.adition.com
filter1.adblockplus.org
filter2.adblockplus.org
# SCHUFA - start
www.meineschufa.de
www.etracker.dewww.etracker.de
# SCHUFA - end
# www.vi.nl - start
www.vi.nl
wpg.blueconic.com
b.scorecardresearch.com
cdn.echoenabled.com
api.echoenabled.com
live.echoenabled.com
sport1.cdp.triple-it.nl
images.performgroup.com
217.118.160.0/24	RTL netherlands
#screenshots.rtl.nl	# redundant
p.jwpcdn.com
vivod.download.kpnstreaming.nl
i.n.jwpltx.com
# www.vi.nl - end
# Whatsapp - start
www.whatsapp.com
whatsappcdn.appspot.com
s.ytimg.com
# Whatsapp - end
# Mozilla.org - start
63.245.208.0/20	mozilla.org mozilla.net
support.cdn.mozilla.net
mozorg.cdn.mozilla.net
cdn.optimizely.com
# Mozilla.org - end
# Deutschlandradio - start
www.deutschlandradio.de
dradio.ivwbox.de
srv.deutschlandradio.de
logc279.xiti.com
www.deutschlandradiokultur.de
ondemand-mp3.dradio.de
193.62.192.0/20	sanger.ac.uk ebi.ac.uk ensembl.org # Europäisches Bioinformatik Institut und Sanger Center
# Deutschlandradio - end
imap.arcor-online.net
195.243.28.128/27	elektronikpraxis.vogel.de  # ...128 - 195.243.28.159
193.158.250.96/27	vogel.de # 193.158.250.96 - 193.158.250.127
# Bahn - start
reiseauskunft.bahn.de	# Not redundant
81.200.198.0/23	BAHN.de
# Bahn - end
www.ivz-aktuell.de
pop3.strato.de
imap.strato.de
193.60.0.0/14	JANET # UK DFN equivalent
31.12.64.0/21	radionomy.net # radio stations
46.252.31.0	www.blitzer.de
137.131.0.0/16	scripps.edu
208.65.72.0/21	blackberry.net
imap-b-mtc-b.mx.aol.com
imap.strato.de
130.75.0.0/16	Uni Hannover
66.135.192.0/19	EBay
66.211.160.0/19	EBay
5.57.17.0/24	booking.com
euw.leagueoflegends.com
185.40.64.0/22	RIOT Games
91.203.96.0/22	Opera.com (autoupdate)
185.26.182.64/26	Opera.com (sitecheck website)
192.53.103.0/24	PTB physikalisch-technische bundesanstalt
# sport1.de
farm.plista.com
www.sport1.de
rce.veeseo.com
# xbox
macs.xboxlive.com
xboxlive.com
# nerd community
linuxinsider.com
lwn.net
linuxtoday.net
# indiegogo
indiegogo.com
bam.nr-data.net
199.101.160.0/22	linkedin.com
109.233.156.0/23	xing.com
62.159.27.0/24	buhl.de
198.136.44.0/22	gameloft.com
# netflix start
www.netflix.de
www.netflix.com
www2-ext-s.nflximg.net
secure.netflix.com
# netflix end
app.dailyme.tv
212.58.240.0/20	bbc.co.uk
91.189.94.0/24	canonical
osmand.net
128.102.0.0/16	NASA
64.4.0.0/18	Microsoft
213.199.160/19	Microsoft
157.60.0.0/16	Microsoft
157.56.0.0/14	Microsoft
157.54.0.0/15	Microsoft
# Germanwings - start
80.149.246.0/24	Germanwings/Eurowings
fast.fonts.net
# Germanwings - end
xmail.timmendorfer-strand.de
www.timmendorfer-strand.de
www.meetup.com
208.65.72.0/21	blackberry.net
imap.gmx.net
212.8.197.168/29 maritim-hotels.de
mail.posteo.de
immonet.de
immobilienscout24.de
alice-dsl.net
91.190.218.0/24	skype
omegle.com
partner.googleadservices.com
translate.googleapis.com
194.149.251.0/24	Volksbank GAD
194.149.250.0/24	Volksbank GAD
mail.dlrg.de
imap3a.mail.vip.ir2.yahoo.com
imap3.mail.vip.ir2.yahoo.com
games.bigfishgames.com
www.bigfishgames.com
www.karls.de
www.karls-shop.de
pop.udag.de
# clashofclans - start
supercell.com
service.supercell.net
174.36.210.49-static.reverse.softlayer.com
ec2-54-195-240-74.eu-west-1.compute.amazonaws.com
# clashofclans - end
# boinc - start
einstein.phys.uwm.edu
# boinc - end
o2mail.de
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
		if [ -z "$(echo $n | tr -d '.0-9/')" ]; then
			echo "I: Interpreting '$n' as IP Number"
			ipdirect $n
		else
			for IP in $(host $n |grep "has address" | cut -f4 -d\ )
			do
				ipdirect $IP
			done
		fi
	fi
done

