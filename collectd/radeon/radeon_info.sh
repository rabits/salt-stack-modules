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
    data=$(sudo aticonfig --odgc --odgt --adapter=all | awk '
    /^Adapter/ {match($0, "^Adapter ([0-9])+ - (.+)", a); number=a[1]; gsub(/ /, "_", a[2]); print "name"a[1]"=\""a[2]"("a[1]")\""}
    /Current Clocks/ {match($0, " *([0-9]+) *([0-9]+)", a); print "freqcpu"number"="a[1]"000000"; print "freqmem"number"="a[2]"000000"}
    /GPU load/ {match($0, "([0-9]+)", a); print "load"number"="a[1]}
    /Temperature/ {match($0, "Temperature - ([0-9]+)", a); print "temp"number"="a[1]}' | sort -u)
    eval "${data}"

    for i in `seq 0 9`
    do
        eval name="\$name$i" freqcpu="\$freqcpu$i" freqmem="\$freqmem$i" load="\$load$i" temp="\$temp$i"
        [ "$name" ] || continue
        echo "PUTVAL ${HOSTNAME}/video_freq-${name}/gauge-cpu interval=${INTERVAL} N:${freqcpu:-'U'}"
        echo "PUTVAL ${HOSTNAME}/video_freq-${name}/gauge-mem interval=${INTERVAL} N:${freqmem:-'U'}"
        echo "PUTVAL ${HOSTNAME}/video_load-${name}/gauge-load interval=${INTERVAL} N:${load:-'U'}"
        echo "PUTVAL ${HOSTNAME}/video_temp-${name}/temperature interval=${INTERVAL} N:${temp:-'U'}"
        eval "name$i=" "freqcpu$i=" "freqmem$i=" "load$i=" "temp$i="
    done
done
