#
# Polipo - cache proxy for tor
#

polipo:
  pkg:
    - installed
  service.running:
    - watch:
      - file: /etc/polipo/config
    - require:
      - pkg: polipo

/etc/polipo/config:
  file.managed:
    - source: salt://polipo/config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: polipo
