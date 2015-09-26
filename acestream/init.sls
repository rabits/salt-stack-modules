#
# AceStream - torrent streams engine
#
# Will install acestream-engine and aceproxy
# You could use it with p2p-strm xbmc plugin or, as proxy, by TV PVR
#
# To use PVR you need:
# 1. Set "PVR IPTV Simple Client" addon settings:
#   * Common settings: Local path, "/srv/aceproxy/list.m3u"
#   * EPG settings: Internet path, "http://api.torrent-tv.ru/ttv.xmltv.xml.gz"
#   * Logo settings: "/srv/aceproxy/channels/logos"
# 2. Set TV settings:
#   * Common: Enabled
#   * EPG: Update time: 720min
#   * Playback: Disabled start playback minimised
#

{% from 'monit/macros.sls' import monit with context %}

{% set dist_def = 'http://dl.acestream.org/ubuntu/12/acestream_3.0.5.1_ubuntu_12.04_x86_64.tar.gz' %}
{% set dist = salt['pillar.get']('acestream:dist', dist_def) %}
{% set dist_dir = salt['pillar.get']('acestream:dist_dir', '/srv/aceproxy') %}
{% set username = salt['pillar.get']('acestream:username', 'acestream') %}

python-aceproxy-pkgs:
  pkg.installed:
    - pkgs:
      - python-psutil
      - python-gevent
      - python-apsw

vlc-nox:
  pkg.installed

{{ dist_dir }}:
  file.recurse:
    - source: salt://acestream/aceproxy
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - exclude_pat: aceconfig.py
    - require:
      - pkg: python-aceproxy-pkgs

/var/log/acestream:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 750
    - require:
      - user: {{ username }}

{{ dist_dir }}/acestream:
  file.directory:
    - user: root
    - group: root
    - mode: 755
  archive.extracted:
    - archive_user: root
    - archive_format: tar
    - tar_options: xf
    - source:
      - '{{ dist }}'
      - '{{ dist_def }}'
    - if_missing: {{ dist_dir }}/acestream/acestreamengine
    - keep: True
    - require:
      - file: {{ dist_dir }}/acestream

{{ dist_dir }}/aceconfig.py:
  file.managed:
    - source: salt://acestream/aceconfig.py.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      dist_dir: {{ dist_dir }}
      username: {{ username }}
    - require:
      - file: {{ dist_dir }}
      - file: {{ dist_dir }}/acestream
      - pkg: vlc-nox

{{ username }}:
  group.present:
    - system: True
  user.present:
    - gid_from_name: True
    - system: True
    - createhome: True
    - groups:
      - video
      - audio
    - require:
      - group: {{ username }}

/etc/init/aceproxy.conf:
  file.managed:
    - source: salt://acestream/upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: {{ dist_dir }}
      - file: {{ dist_dir }}/aceconfig.py
      - user: {{ username }}

aceproxy:
  service.running:
    - require:
      - user: {{ username }}
      - file: /var/log/acestream
    - watch:
      - file: {{ dist_dir }}
      - file: {{ dist_dir }}/aceconfig.py
      - file: /etc/init/aceproxy.conf

{{ monit('acestream') }}

{{ dist_dir }}/channels.tsv:
  file.managed:
    - source: salt://acestream/channels.tsv
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: {{ dist_dir }}

{{ dist_dir }}/makelist.py:
  file.managed:
    - source: salt://acestream/makelist.py
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ dist_dir }}

{{ dist_dir }}/channels:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 755
    - require:
      - file: {{ dist_dir }}

{{ dist_dir }}/channels/list.m3u:
  file.managed:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644

{{ dist_dir }}/channels/lastrun.log:
  file.managed:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644

{{ dist_dir }}/makelist.py 'http://super-pomoyka.us.to/trash/ttv-list/ttv.all.proxy.xspf' {{ dist_dir }}/channels/list.m3u {{ dist_dir }}/channels.tsv > {{ dist_dir }}/channels/lastrun.log 2>&1:
  cron.present:
    - identifier: acestream_makelist
    - user: {{ username }}
    - minute: '*/15'
    - require:
      - file: {{ dist_dir }}/makelist.py
      - file: {{ dist_dir }}/channels
      - file: {{ dist_dir }}/channels.tsv
      - file: {{ dist_dir }}/channels/list.m3u
      - file: {{ dist_dir }}/channels/lastrun.log
