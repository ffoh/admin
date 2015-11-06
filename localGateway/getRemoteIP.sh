#!/bin/dash
w3m -M -dump whatismyip.com  | sed -e '1,/^Your/d'|head -n 1
