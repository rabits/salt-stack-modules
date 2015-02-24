#!/usr/bin/python2
# -*- coding: UTF-8 -*-

# Usage:
#  ./list.py http://www.trambroid.com/playlist.xspf [channels.tsv] [list.m3u]

import sys, os
from xml.dom.minidom import parseString
import urllib2
import codecs
from types import DictType

required_channels = None

output = []
out_file = 'list.m3u'

if len(sys.argv) > 2:
    print "Get list of groups & channels"
    required_channels = {}
    with codecs.open(sys.argv[2], "r", "utf-8") as channels:
        counter = 0
        for channel in channels:
            if channel[:1] == '#':
                continue
            channel = channel[:-1].split('\t')
            group = channel[0]
            title = channel[1]
            required_channels[title] = { 'group': group, 'pos': counter }
            output.append(title)
            counter += 1
    print "  required channels: %i" % len(required_channels)

if len(sys.argv) > 3:
    out_file = sys.argv[3]

logo_dir = os.path.join(os.path.dirname(out_file), 'logo')

data = parseString(urllib2.urlopen(sys.argv[1]).read())
for track in data.documentElement.getElementsByTagName('track'):
    track_data = {}
    track_data['title'] = track.getElementsByTagName('title')[0].firstChild.nodeValue
    track_data['group'] = ''
    pos = len(output)
    if required_channels != None:
        if track_data['title'] not in required_channels:
            print "Skipping channel: %s" % track_data['title'].encode('utf-8')
            continue
        else:
            print "Processing channel: %s" % track_data['title'].encode('utf-8')
            track_data['group'] = required_channels[track_data['title']]['group']
            pos = required_channels[track_data['title']]['pos']

    track_data['location'] = track.getElementsByTagName('location')[0].firstChild.nodeValue.replace('acestream://', 'http://127.0.0.1:8000/pid/') + '/stream.mp4'
    image = track.getElementsByTagName('image')[0].firstChild.nodeValue
    image_file = logo_dir + '/' + image.split('/')[-1]
    if not os.path.isfile(image_file):
        print "  Download logo: %s" % image
        try:
            if not os.path.isdir(logo_dir):
                os.makedirs(logo_dir)

            u = urllib2.urlopen(image, None, 30) 
            with open(image_file, 'wb') as outfile:
                size = int(u.info().getheaders('Content-Length')[0])
                while True:
                    b = u.read(8192)
                    if not b:
                        break
                    outfile.write(b)
            track_data['logo'] = image.split('/')[-1].split('.')[0]
        except Exception as e:
            print "    error: %s" % str(e)
            track_data['logo'] = ''
    else:
        track_data['logo'] = image.split('/')[-1].split('.')[0]

    output[pos] = track_data

with codecs.open(out_file, "w", "utf-8") as fout:
    fout.write('#EXTM3U url-tvg="http://api.torrent-tv.ru/ttv.xmltv.xml.gz"\n')
    for channel in output:
        if not type(channel) is DictType:
            print "Warning: not found channel '%s'" % channel.encode('utf-8')
            continue
        fout.write('#EXTINF:-1 group-title="%s" tvg-name="%s" tvg-logo="%s",%s\n' % (channel['group'], channel['title'].replace(' ', '_'), channel['logo'], channel['title']))
        fout.write('%s\n' % channel['location'])
