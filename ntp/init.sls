#
# NTP time server
#

ntp:
  pkg:
    - installed
  service:
    - running
    - require:
      - pkg: ntp

/etc/ntp.conf:
  file.managed:
    - source: salt://ntp/ntp.conf
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: ntp
    - watch_in:
      - service: ntp
