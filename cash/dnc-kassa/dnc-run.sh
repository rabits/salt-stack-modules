#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

# Run dnc kassa with specific library path

export LD_LIBRARY_PATH=/usr/local/lib/dnc
/usr/bin/reshka
exit $?
