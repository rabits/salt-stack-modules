#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

# RStream archive cleaner if we have < 200GB in /srv partition

export ARCHIVE="/srv/streams/archive"

# If free space < 200GB - we need to clean some old streams
for i in $(/usr/bin/seq 1 6)
do
    available_space=$(/bin/df | /bin/grep '/srv$' | /usr/bin/awk '{ print $(NF-2) }')
    if [ "${available_space}" -lt "$((1024*1024*200))" ]
    then
        item=$(/bin/ls -rt "$ARCHIVE" | /bin/grep -v log | /usr/bin/head -1)
        echo "RSTREAM: Available space in /srv - $(($available_space/1024/1025))GB, we need to remove old data '$ARCHIVE/$item'"
        /bin/rm -rf "$ARCHIVE/$item"
    else
        echo "RSTREAM: Available space in /srv - $(($available_space/1024/1025))GB, this is ok"
        break
    fi
done
