#
# rTorrent downloader
#

{% set xbmc_present = salt['additional.state_in'](['xbmc']) %}

rtorrent:
  pkg:
    - installed
    - pkgs:
      - rtorrent
      - dtach
  group:
    - present
  user.present:
    - gid_from_name: True
    {%- if xbmc_present %}
    - groups:
      - xbmc
    {%- endif %}
    - require:
      - group: rtorrent
      - pkg: rtorrent
  service.running:
    - require:
      - user: rtorrent
    - watch:
      - pkg: rtorrent

/srv/torrent/incomplete:
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

/srv/torrent/completed:
  file.directory:
    - user: rtorrent
    - group: rtorrent
    - mode: 755
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

{% if xbmc_present %}
{% for name in ['music', 'movies', 'serials', 'clips'] %}
/srv/torrent/watch/{{ name }}:
  file.directory:
    - user: rtorrent
    - group: rtorrent
    - mode: 775
    - makedirs: True
    - require:
      - user: rtorrent
    - require_in:
      - file: /home/rtorrent/.rtorrent.rc
{% endfor %}
{% endif %}

/srv/media/torrents:
  file.directory:
    - user: rtorrent
    - group: rtorrent
    - mode: 777
    - makedirs: True

/home/rtorrent/.rtorrent.rc:
  file.managed:
    - source: salt://rtorrent/rtorrent.rc.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - contet:
      xbmc_present: {{ xbmc_present }}
    - require:
      - pkg: rtorrent
      - user: rtorrent
      - file: /srv/media/torrents
      - file: /srv/torrent/watch
      - file: /srv/torrent/incomplete
      - file: /srv/torrent/sessions
      - file: /srv/torrent/completed
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
