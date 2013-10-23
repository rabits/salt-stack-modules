#
# rTorrent downloader
#

rtorrent:
  pkg:
    - installed
    - pkgs:
      - rtorrent
      - dtach
  group:
    - present
  user.present:
    - gid: {{ salt['file.group_to_gid']('rtorrent') }}
    - require:
      - group: rtorrent
      - pkg: rtorrent
  service.running:
    - require:
      - user: rtorrent
    - watch:
      - pkg: rtorrent

/srv/torrent/process:
  file.directory:
    - user: rtorrent
    - group: rtorrent
    - mode: 750
    - makedirs: True
    - require:
      - user: rtorrent

/srv/torrent/sessions:
  file.directory:
    - user: rtorrent
    - group: rtorrent
    - mode: 750
    - makedirs: True
    - require:
      - user: rtorrent

/srv/torrent/watch:
  file.directory:
    - user: rtorrent
    - group: rtorrent
    - mode: 775
    - makedirs: True
    - require:
      - user: rtorrent

/srv/media/torrents:
  file.directory:
    - user: rtorrent
    - group: rtorrent
    - mode: 777
    - makedirs: True

/home/rtorrent/.rtorrent.rc:
  file.managed:
    - source: salt://rtorrent/rtorrent.rc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - require:
      - pkg: rtorrent
      - user: rtorrent
      - file: /srv/media/torrents
      - file: /srv/torrent/watch
      - file: /srv/torrent/process
      - file: /srv/torrent/sessions
    - watch_in:
      - service: rtorrent

/etc/init/rtorrent.conf:
  file.managed:
    - source: salt://rtorrent/upstart.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: rtorrent
      - user: rtorrent
    - watch_in:
      - service: rtorrent
