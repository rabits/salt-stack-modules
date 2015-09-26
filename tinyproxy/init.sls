#
# Tinyproxy - used to access hidden networks
#

tinyproxy:
  pkg:
    - installed
  service.running:
    - watch:
      - file: /etc/tinyproxy.conf
    - require:
      - pkg: tinyproxy

/etc/tinyproxy.conf:
  file.managed:
    - source: salt://tinyproxy/tinyproxy.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: tinyproxy
