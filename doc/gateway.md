= Setup of regular Freifunk Gateway for Freifunk Ostholstein =

== Debian packages to install ==

All packages required for the operation of a Freifunk Gateway were packaged by members of Freifunk Ostholstein for Debian Linux and are available from the regular servers of that Linux distribution.

=== Packages for basic gateway functionality ===

alfred
openvpn
fastd
bind9
git
isc-dhcp-server
openssh-server
fail2ban
batctl

=== Packages for extra comfort ===

deborphan
debfoster
host
bmon
vim
screen

=== Packages for extended functionality ===

quilt
build-essential
popularity-contest


== Things to do ==

=== once ===

useradd -r fastd
echo "42	freifunk"> /etc/ip_route2/rt_tables
cd /root && git clone https://github.com/ffoh/admin

=== once - if the router shall show splash pages ===

cd / && git clone splashpages@splash.bfo.online:/splashpages

=== after every reset ===

cd /root && ./iptables.sh

