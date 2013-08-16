#
# Collectd plugin: nut
#

/etc/collectd/collectd.d/nut.conf:
  file.managed:
    - source: salt://collectd/nut/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
    - watch_in:
      - service: collectd
