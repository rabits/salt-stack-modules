#
# Collectd plugin: nginx
#

/etc/collectd/collectd.d/nginx.conf:
  file.managed:
    - source: salt://collectd/nginx/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
    - watch_in:
      - service: collectd

