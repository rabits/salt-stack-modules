#
# Monit - system & services monitor client
#

include:
  - sensors

{% set mmonit_address = salt['pillar.get']('mmonit:address', '127.0.0.1') %}
{% set mmonit_user = salt['pillar.get']('mmonit:user', 'monit') %}
{% set mmonit_password = salt['pillar.get']('mmonit:password', '') %}

monit:
  pkg:
    - installed
  service.running:
    - reload: True
    - require:
      - pkg: monit

/etc/monit/monitrc:
  file.managed:
    - source: salt://monit/monitrc.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - context:
      mmonit_address: {{ mmonit_address }}
      mmonit_user: {{ mmonit_user }}
      mmonit_password: {{ mmonit_password }}
    - watch_in:
      - service: monit
    - require:
      - pkg: lm-sensors
      - pkg: monit
