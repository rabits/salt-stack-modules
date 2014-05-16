#
# Transmission - torrent daemon
#

{% set xbmc_present = salt['additional.state_in'](['xbmc']) %}

transmission-daemon:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: transmission-daemon

{% if xbmc_present -%}
debian-transmission:
  user.present:
    - groups:
      - debian-transmission
      - xbmc
{%- endif %}

/srv/torrent/incomplete:
  file.directory:
    - user: debian-transmission
    - group: debian-transmission
    - mode: 750
    - makedirs: True
    - require:
      - pkg: transmission-daemon

/srv/torrent/completed:
  file.directory:
    - user: debian-transmission
    - group: debian-transmission
    - mode: 755
    - makedirs: True
    - require:
      - pkg: transmission-daemon

/srv/torrent/watch:
  file.directory:
    - user: debian-transmission
    - group: debian-transmission
    - mode: 775
    - makedirs: True
    - require:
      - pkg: transmission-daemon

/srv/media/torrents:
  file.directory:
    - user: debian-transmission
    - group: debian-transmission
    - mode: 777
    - makedirs: True
    - require:
      - pkg: transmission-daemon

/etc/transmission-daemon/script-done.sh:
  file.managed:
    - source: salt://transmission/daemon/script-done.sh.jinja
    - template: jinja
    - user: root
    - group: debian-transmission
    - mode: 750
    - context:
      xbmc_present: {{ xbmc_present }}
    - require:
      - pkg: transmission-daemon

/etc/transmission-daemon/settings.json:
  file.managed:
    - source: salt://transmission/daemon/settings.json.jinja
    - template: jinja
    - user: debian-transmission
    - group: debian-transmission
    - mode: 600
    - require:
      - pkg: transmission-daemon
      - file: /srv/media/torrents
      - file: /srv/torrent/watch
      - file: /srv/torrent/incomplete
      - file: /srv/torrent/completed
      - file: /etc/transmission-daemon/script-done.sh
    - watch_in:
      - service: transmission-daemon
