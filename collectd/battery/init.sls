#
# Collectd plugin: battery
#

/etc/collectd/collectd.d/battery.conf:
  file.managed:
    - source: salt://collectd/battery/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
    - watch_in:
      - service: collectd

