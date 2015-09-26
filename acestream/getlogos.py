#!/usr/bin/python2
# -*- coding: UTF-8 -*-

# Usage:
#  ./getlogos.py 'http://www.trambroid.com/playlist.xspf'

import sys, os
from xml.dom.minidom import parseString
import urllib2

logo_dir = 'getlogos'

if not os.path.isdir(logo_dir):
    os.makedirs(logo_dir)

# Start parsing
data = parseString(urllib2.urlopen(sys.argv[1]).read())

for track in data.documentElement.getElementsByTagName('track'):
    track_data = {}
    track_data['title'] = track.getElementsByTagName('title')[0].firstChild.nodeValue

    print "Processing channel: %s" % track_data['title'].encode('utf-8')

    if track.getElementsByTagName('image'):
        image = track.getElementsByTagName('image')[0].firstChild.nodeValue
        image_file = logo_dir + '/' + (track_data['title'] + image.split('.')[-1]).replace('/', '_')
        if not os.path.isfile(image_file):
            print "  Download logo: %s" % image
            try:
                u = urllib2.urlopen(image, None, 30) 
                with open(image_file, 'wb') as outfile:
                    size = int(u.info().getheaders('Content-Length')[0])
                    while True:
                        b = u.read(8192)
                        if not b:
                            break
                        outfile.write(b)
            except Exception as e:
                print "    error: %s" % str(e)
