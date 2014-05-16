#
# AceStream - torrent streams engine
#
# Will install acestream-engine and aceproxy
# You could use it with p2p-strm xbmc plugin or, as proxy, by TV PVR
#
# To use PVR you need:
# 1. Set "PVR IPTV Simple Client" addon settings:
#   * Common settings: Local path, "/srv/aceproxy/list.m3u"
#   * EPG settings: Internet path, "http://www.teleguide.info/download/new3/xmltv.xml.gz"
#   * Logo settings: "/srv/aceproxy/icons/"
# 2. Set TV settings:
#   * Common: Enabled
#   * EPG: Update time: 720min
#   * Playback: Disabled start playback minimised
#

acestream-repo:
  pkgrepo.managed:
   - name: deb http://repo.acestream.org/ubuntu/ quantal main
   - key_url: http://repo.acestream.org/keys/acestream.public.key

acestream-engine:
  pkg.installed:
    - require:
      - pkgrepo: acestream-repo

/etc/init/acestream.conf:
  file.managed:
    - source: salt://acestream/upstart-acestream.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: acestream-engine
      - user: acestream

acestream:
  group:
    - present
  user.present:
    - gid_from_name: True
    - groups:
      - video
      - audio
    - require:
      - pkg: acestream-engine
      - group: acestream
  service.running:
    - require:
      - user: acestream
    - watch:
      - pkg: acestream-engine
      - file: /etc/init/acestream.conf

python-gevent:
  pkg.installed

vlc-nox:
  pkg.installed

/etc/init/acevlc.conf:
  file.managed:
    - source: salt://acestream/upstart-acevlc.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: vlc-nox
      - user: acestream

acevlc:
  service.running:
    - require:
      - user: acestream
    - watch:
      - pkg: vlc-nox
      - file: /etc/init/acevlc.conf

/srv/aceproxy:
  file.recurse:
    - source: salt://acestream/aceproxy
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - exclude_pat: aceconfig.py
    - require:
      - pkg: python-gevent
      - pkg: vlc-nox

/srv/aceproxy/aceconfig.py:
  file.managed:
    - source: salt://acestream/aceconfig.py
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /srv/aceproxy

/etc/init/aceproxy.conf:
  file.managed:
    - source: salt://acestream/upstart-aceproxy.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /srv/aceproxy
      - file: /srv/aceproxy/aceconfig.py
      - user: acestream

aceproxy:
  service.running:
    - require:
      - user: acestream
      - service: acestream
      - service: acevlc
    - watch:
      - file: /srv/aceproxy
      - file: /srv/aceproxy/aceconfig.py
      - file: /etc/init/aceproxy.conf

/srv/aceproxy/list.m3u:
  file.managed:
    - source: salt://acestream/list.m3u
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /srv/aceproxy

/srv/aceproxy/icons:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /srv/aceproxy
