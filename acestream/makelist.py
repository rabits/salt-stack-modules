#!/usr/bin/python2
# -*- coding: UTF-8 -*-

# Usage:
#  ./makelist.py 'http://super-pomoyka.us.to/trash/ttv-list/ttv.all.proxy.xspf' [list.m3u] [channels.tsv]

import sys, os, datetime, time
from xml.dom.minidom import parseString
import urllib2
import codecs
from types import DictType

output = []
groups = {}
out_file = 'list.m3u'
required_channels = None

if len(sys.argv) > 2:
    out_file = sys.argv[2]

if len(sys.argv) > 3:
    print "Get list of groups & channels"
    required_channels = {}
    with codecs.open(sys.argv[3], "r", "utf-8") as channels:
        counter = 0
        for channel in channels:
            if channel[:1] == '#':
                continue
            channel = channel[:-1].split('\t')
            title = channel[0]
            required_channels[title] = { 'pos': counter }
            if len(channel) > 1:
                required_channels[title]['group'] = channel[1]
            output.append(title)
            counter += 1
    print "  required channels: %i" % len(required_channels)

logo_dir = os.path.join(os.path.dirname(out_file), 'logo')

# Check date of modification
localmtime = os.path.getmtime(out_file) if os.path.isfile(out_file) else 0

urlfile = urllib2.urlopen(sys.argv[1])
urltime = time.mktime(datetime.datetime.strptime(urlfile.info().get('Last-Modified'), "%a, %d %b %Y %H:%M:%S %Z").timetuple())
if urltime < localmtime:
    print("No changes in remote file - skipping run")
#    sys.exit()

# Start parsing & modification
data = parseString(urlfile.read())

for node in data.documentElement.getElementsByTagName('vlc:node'):
    grouptitle = node.getAttribute('title')
    for item in node.getElementsByTagName('vlc:item'):
        groups[item.getAttribute('tid')] = grouptitle

for track in data.documentElement.getElementsByTagName('track'):
    track_data = {}
    track_data['title'] = track.getElementsByTagName('title')[0].firstChild.nodeValue

    pos = len(output)

    if required_channels != None:
        if track_data['title'] not in required_channels:
            print "Skipping channel: %s" % track_data['title'].encode('utf-8')
            continue
        else:
            print "Processing channel: %s" % track_data['title'].encode('utf-8')
            pos = required_channels[track_data['title']]['pos']
            if 'group' in track_data['title']:
                track_data['group'] = required_channels[track_data['title']]['group']
    else:
        print "Processing channel: %s" % track_data['title'].encode('utf-8')

    track_data['location'] = track.getElementsByTagName('location')[0].firstChild.nodeValue.replace('http://192.168.2.1:82/', 'http://127.0.0.1:8000/')

    extension = track.getElementsByTagName('extension')
    if 'group' not in track_data and extension:
        tid = extension[0].getElementsByTagName('vlc:id')
        if tid:
            tid_v = tid[0].firstChild.nodeValue
            if tid_v in groups:
                track_data['group'] = groups[tid_v]

    logoname = track_data['title'].replace('/', '_')
    if not os.path.isfile(logo_dir + '/' + logoname + '.png'):
        if track.getElementsByTagName('image'):
            image = track.getElementsByTagName('image')[0].firstChild.nodeValue
            image_file = logo_dir + '/' + logoname + image.split('.')[-1].replace('/', '_')
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
                    track_data['logo'] = logoname + image.split('.')[-1].replace('/', '_')
                except Exception as e:
                    print "    error: %s" % str(e)
            else:
                track_data['logo'] = logoname + image.split('.')[-1].replace('/', '_')
    else:
        track_data['logo'] = logoname + '.png'

    if required_channels != None:
        output[pos] = track_data
    else:
        output.append(track_data)

with codecs.open(out_file, "w", "utf-8") as fout:
    fout.write('#EXTM3U url-tvg="http://api.torrent-tv.ru/ttv.xmltv.xml.gz"\n')
    for channel in output:
        if not type(channel) is DictType:
            print "Warning: not found channel '%s'" % channel.encode('utf-8')
            continue
        wstring = ['#EXTINF:-1']
        if 'group' in channel:
            wstring.append('group-title="%s"' % channel['group'])
        if 'logo' in channel:
            wstring.append('tvg-logo="%s"' % channel['logo'])
        wstring.append('tvg-name="%s",%s\n' % (channel['title'].replace(' ', '_'), channel['title']))
        fout.write(' '.join(wstring))
        fout.write('%s\n' % channel['location'])

# Update PVR channels in Kodi
import socket
import time

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('127.0.0.1', 9090))
s.send('''[
  {"jsonrpc":"2.0","id":0,"method":"GUI.ActivateWindow","params":{"window":"pvrsettings"}},
  {"jsonrpc":"2.0","id":1,"method":"Input.Right"},
  {"jsonrpc":"2.0","id":2,"method":"Input.Up"},
  {"jsonrpc":"2.0","id":3,"method":"Input.Up"},
  {"jsonrpc":"2.0","id":4,"method":"Input.Select"},
  {"jsonrpc":"2.0","id":5,"method":"Input.Left"},
  {"jsonrpc":"2.0","id":6,"method":"Input.Select"}]
''')
print s.recv(4096)

time.sleep(5) # Wait till cancel button disappears

s.send('''{"jsonrpc":"2.0","id":7,"method":"Input.Back"}
''')
print s.recv(4096)

s.close()
