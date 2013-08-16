#
# Collectd plugin: ping
#

liboping0:
  pkg.installed:
    - watch_in:
      - service: collectd

/etc/collectd/collectd.d/ping.conf:
  file.managed:
    - source: salt://collectd/ping/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
    - watch_in:
      - service: collectd

