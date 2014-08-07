#!/bin/bash

set -e

NoForwardIPs=$(cat <<EOEVIL| cut -f1
111.13.12.89
EOEVIL
)

for i in $NoForwardIPs
do
	echo "I: Blocking $i"
	iptables -I FORWARD -d "$i" -m comment --comment 'malicious site (added by evil.sh)' -j REJECT
	iptables -I FORWARD -s "$i" -m comment --comment 'malicious site (added by evil.sh)' -j DROP
done
