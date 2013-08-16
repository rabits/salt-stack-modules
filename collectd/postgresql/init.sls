#
# Collectd plugin: postgresql
#

/etc/collectd/collectd.d/postgresql.conf:
  file.managed:
    - source: salt://collectd/postgresql/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
    - watch_in:
      - service: collectd

