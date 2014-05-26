#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

FREE_MEM=`LANG=C free | awk '/buffers\/cache/{print (100 - ($4/($3+$4) * 100.0));}'`
printf "M %.f%%" $FREE_MEM
