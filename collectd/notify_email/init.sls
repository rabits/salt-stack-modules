#
# Collectd plugin: notify_email
#

libesmtp6:
  pkg.installed:
    - watch_in:
      - service: collectd

/etc/collectd/collectd.d/notify_email.conf:
  file.managed:
    - source: salt://collectd/notify_email/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
    - watch_in:
      - service: collectd

