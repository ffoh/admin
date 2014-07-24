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
	#if ! ip route list table freifunk | grep -q "$ip"; then
	if ! ip route get $ip from 10.135.8.100 iif bat0 | grep -q eth0; then
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

IPs=$(cat <<EOIPS | grep -v ^# |cut -f1|sort -u
#
ostholstein.freifunk.net
gw1.ostholstein.freifunk.net
gw2.ostholstein.freifunk.net
# much sought after
ad.doubleclick.net
#de.sitestat.com
17.0.0.0/8	apple
# 
accounts.google.com
apis.google.de
gmail.com
google.com
google.de
google-public-dns-a.google.com
google-public-dns-b.google.com
id.google.de
mail.google.com
oauth.googleusercontent.com
plus.google.com
plusone.google.com
ssl.gstatic.com
talkgadget.google.com
www.google-analytics.com
www.google.com
www.google.de
# spiegel - start
spiegel.de
www.spiegel.de
m.spiegel.de
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
prod.spiegel.de
script.ioam.de
qs.ioam.de
qs.ivwbox.de
dc72.s290.meetrics.net
ad2.adfarm1.adition.com
adserv.quality-channel.de
vt.adition.com
www.google-analytics.com
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
69.171.224.0/19	facebook
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
# ebay - start
ebay.de
www.ebay.de
www.ebay.com
ebay.ivwbox.de
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
github.com
last.fm
www.last.fm
lastfm.de
www.lastfm.de
google-analytics.com
www.google-analytics.com
facebook.com
www.facebook.com
# GMX - start
gmx.de
gmx.net
www.gmx.de
www.gmx.net
navigator.gmx.net
s3.amazonaws.com
fbcdn-profile-a.akamaihd.net
i0.gmx.net
s.uicdn.com
gmx.ivwbox.de
s.uicdn.com
uim.tifbs.net
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
webmail.uksh.de
www.uni-luebeck.de
webmail.uk-sh.de
www.uksh.de
# OOKLA Speedtest - start
www.googleadservices.com
www.gstatic.com
www.speedtest.net
a.adroll.com
a.c.appier.net
ads.ookla.com
analytics.twitter.com
by.uservoice.com
c.speedtest.net
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
# OOKLA Speedtest - end
imap.web.de
service-st11-a.gc.apple.com
www.apple.com
api-7b.v.dropbox.com
www.dropbox.com
www.amung.us
amung.us
hsp.web.de
www.web.de
web.de
home.navigator.web.de
3c.web.de
webdessl.ivwbox.de
www.wikimedia.org
wikimedia.org
upload.wikimedia.org
meta.wikimedia.org
bits.wikimedia.org
de.wikipedia.org
commons.wikimedia.org
login.wikimedia.org
email01.t-online.de
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
a.tile.openstreetmap.org
b.tile.openstreetmap.org
c.tile.openstreetmap.org
www.gravatar.com
i0.wp.com
dev.virtualearth.net
ecn.t0.tiles.virtualearth.net
ecn.t1.tiles.virtualearth.net
ecn.t2.tiles.virtualearth.net
ecn.t3.tiles.virtualearth.net
a.tiles.mapbox.com
b.tiles.mapbox.com
c.tiles.mapbox.com
# RTL - start
hds.webclips.fra.rtl.de
bilder.static-fra.de
cdn.static-fra.de
www.rtl.de
static.plista.com
autoimg.rtl.de
autoimg.static-fra.de
bilder.akamai.rtl.de
fbcdn-profile-a.akamaihd.net
px1.vtrtl.de
bilder.rtl.de
qs.ivwbox.de
count.rtl.de
rtl.ivwbox.de
static.plista.com
tracking.rtl.de
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
i.ligatus.com
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
iphone-xml-l.booking.com
www.booking.com
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
mqtt-shv-10-frc1.facebook.com
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
ad.doubleclick.net
ad-emea.doubleclick.net
ad.yieldlab.net
admin.brightcove.com
amv3-tslogging.touchcommerce.com
api.adrtx.net
api.bizographics.com
www.skygo.sky.de
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
b.scorecardresearch.com
cdn1.smartadserver.com
cdn.adrtx.net
cdn.krxd.net
cm.g.doubleclick.net
d2oh4tlt9mrke9.cloudfront.net
dis.criteo.com
eas.apm.emediate.eu
ecustomeropinions.com
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
# Carelink Medtronic - start
carelink.minimed.com
b.medtronic.com
# Carelink Medtronic - end
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
connect.facebook.net
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
173.194.0.0/16	youtube.com
#s.youtube.com	redundant
#www.youtube.com	redundant
#www.youtube-nocookie.com	redundant
98.136.0.0/14	yahoo.com
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
