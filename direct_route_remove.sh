#!/bin/dash
ip route show table freifunk | grep -v default | while read route; do ip route del $route table freifunk; done
