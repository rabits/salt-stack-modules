#
# SQUID proxy
#

squid:
  pkg.installed

squid3:
  service.running:
    - require:
      - pkg: squid

/etc/squid3/squid.conf:
  file.managed:
    - source: salt://squid/squid.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: squid
    - watch_in:
      - service: squid3
