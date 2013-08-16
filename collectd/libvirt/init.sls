#
# Collectd plugin: libvirt
#

/etc/collectd/collectd.d/libvirt.conf:
  file.managed:
    - source: salt://collectd/libvirt/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
    - watch_in:
      - service: collectd

