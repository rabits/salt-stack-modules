#
# Collectd plugin: openvpn
#

include:
  - collectd.ping

/etc/collectd/collectd.d/openvpn.conf:
  file.managed:
    - source: salt://collectd/openvpn/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
    - watch_in:
      - service: collectd

