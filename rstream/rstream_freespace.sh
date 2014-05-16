#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

# RStream archive cleaner if we have < 200GB in /srv partition

export PATH="/bin:/usr/bin:/sbin:/usr/sbin"
export ARCHIVE="/srv/streams/archive"

# If free space < 200GB - we need to clean some old streams
for i in $(seq 1 6)
do
    available_space=$(df -P "${ARCHIVE}" | tail -1 | awk '{ print $4 }')
    if [ "${available_space}" -lt "$((1024*1024*150))" ]
    then
        item=$(ls -rt "$ARCHIVE" | grep -v log | head -1)
        echo "RSTREAM: Available space in /srv - $(($available_space/1024/1025))GB, we need to remove old data '$ARCHIVE/$item'"
        rm -rf "$ARCHIVE/$item"
    else
        echo "RSTREAM: Available space in /srv - $(($available_space/1024/1025))GB, this is ok"
        break
    fi
done
