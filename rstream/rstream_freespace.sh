#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

# RStream archive cleaner if we have < 200GB in /srv partition

export PATH="/bin:/usr/bin:/sbin:/usr/sbin"
export ARCHIVE="/srv/streams/archive"

# Find oldest directories in the archive
# If free space < 150GB - we need to clean some old streams
find "$ARCHIVE" -mindepth 1 -type d -printf '%T@\t%p\n' | sort -g | head -n6 | cut -f2- \
    | while IFS= read -r item
do
    available_space=$(df --block-size=1G -P "${ARCHIVE}" | tail -1 | tr -s ' ' | cut -d' ' -f4)
    if [ "${available_space}" -lt "150" ]
    then
        echo "RSTREAM: Available space in $ARCHIVE: ${available_space}GB, we need to remove old data '$item'"
        rm -rf "$item"
    else
        echo "RSTREAM: Available space in $ARCHIVE: ${available_space}GB, it's ok"
        break
    fi
done
