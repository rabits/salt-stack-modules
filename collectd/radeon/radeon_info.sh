#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

# Collectd radeon videocard Temp, Freq and Load report

HOSTNAME="${COLLECTD_HOSTNAME:-`hostname -f`}"
INTERVAL="${COLLECTD_INTERVAL:-60}"

for display in $(ls /tmp/.X11-unix | grep -o '[0-9]\+')
do
    export DISPLAY=:${display}
    sudo /usr/bin/xhost +local:localuser:collectd 1>/dev/null 2>&1
    data=$(sudo aticonfig --odgc --odgt --adapter=all | sed -e '
        s/^Adapter \([0-9]\+\)\+ - \(.\+\)$/name="\2(\1)"/; T label; s/ /_/g; t; :label
        s/^.*Current Clocks : *\([0-9]\+\) *\([0-9]\+\)/freqcpu=\1000000\nfreqmem=\2000000/; t;
        s/.*GPU load : *\([0-9]\+\).*$/load=\1/; t;
        s/^.*Temperature - *\([0-9]\+\).*$/temp=\1/; t;
        s/.\+//' 2>/dev/null | awk 'NF' | sort -u)
    eval "${data}"

    echo "PUTVAL ${HOSTNAME}/video_freq-${name}/gauge-cpu interval=${INTERVAL} N:${freqcpu:-'U'}"
    echo "PUTVAL ${HOSTNAME}/video_freq-${name}/gauge-mem interval=${INTERVAL} N:${freqmem:-'U'}"
    echo "PUTVAL ${HOSTNAME}/video_load-${name}/gauge-load interval=${INTERVAL} N:${load:-'U'}"
    echo "PUTVAL ${HOSTNAME}/video_temp-${name}/temperature interval=${INTERVAL} N:${temp:-'U'}"
done
