#!/bin/sh
# WARNING:
# This file is under CM control - all manual changes will be removed
#

# Startup WM with Cash script

matchbox-window-manager &
/usr/local/bin/dnc-run.sh
pkill matchbox-window
