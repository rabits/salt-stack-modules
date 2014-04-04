#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

io_line_count=$((`iostat -d -x -m | wc -l`+1)); 
iostat -d -x -m 1 2 -z | tail -n +$io_line_count | grep -v "Device" | awk 'BEGIN{rsum=0; wsum=0}{ rsum+=$6; wsum+=$7} END {printf "D r%.2f w%.2f", rsum, wsum}'
