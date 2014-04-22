#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

io_line_count=$((`iostat -d -x -m | wc -l`+1)); 
iostat -d -x -k 1 2 -z | tail -n +$io_line_count | grep -v "Device" | awk 'BEGIN{rsum=0; wsum=0}{ rsum+=$6; wsum+=$7} END {printf "r%3dK w%3dK", rsum, wsum}'
