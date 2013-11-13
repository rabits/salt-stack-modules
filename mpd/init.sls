#
# MPD audio server
#

mpd:
  pkg:
    - installed
  service:
    - running

/etc/mpd.conf:
  file.managed:
    - source: salt://mpd/mpd.conf
    - user: root
    - group: audio
    - mode: 640
    - require:
      - pkg: mpd
    - watch_in:
      - service: mpd
