#
# Collectd plugin: radeon
#

/usr/local/sbin/radeon_info.sh:
  file.managed:
    - source: salt://collectd/radeon/radeon_info.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /etc/sudoers.d/collectd_radeon

/etc/collectd/collectd.d/radeon.conf:
  file.managed:
    - source: salt://collectd/radeon/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/collectd/collectd.d
      - file: /usr/local/sbin/radeon_info.sh
    - watch_in:
      - service: collectd

/etc/sudoers.d/collectd_radeon:
  file.managed:
    - user: root
    - group: root
    - mode: 640
    - contents: "collectd ALL=NOPASSWD: /usr/bin/aticonfig --odgc --odgt --adapter=all, /usr/bin/xhost +local\\:localuser\\:collectd\n"
    - require:
      - user: collectd

