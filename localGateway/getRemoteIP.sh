#!/bin/dash
w3m -4 -M -dump whatismyip.com  | grep "Your Public"|head -n 1
