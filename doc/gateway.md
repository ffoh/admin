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
netstat-nat

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

```
useradd -r fastd
echo "42	freifunk"> /etc/ip_route2/rt_tables
cd /root && git clone https://github.com/ffoh/admin
cat > /etc/default/isc-dhcp-server <<EOCAT
INTERFACESv4="bat0"
#INTERFACESv6="bat0"
EOCAT
sysctl net.ipv4.ip_forward=1
sysctl net.ipv6.conf.all.forwarding=1
sysctl net.ipv6.neigh.default.gc_thresh1=512
sysctl net.ipv6.neigh.default.gc_thresh2=2048
sysctl net.ipv6.neigh.default.gc_thresh3=4096
cat > /etc/modules <<EOCAT
iptable_nat
batman_adv
EOCAT
```

=== once - if the router shall show splash pages ===

Well, you need to install nodogsplash, we are afraid. This is yet not redistributed with Debian.

```
cd / && git clone splashpages@splash.bfo.online:/splashpages
cd /root/git && git clone splashpages@splash.bfo.online:/git/bfoadmin
```

=== after every reset ===

```
cd /root && ./iptables.sh
cd /root && ./direct_route.sh
```

