#
# OpenSSL crypto library
#

openssl:
  pkg.installed

{{ pillar['ssl']['home'] }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755

{{ pillar['ssl']['ca'] }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ pillar['ssl']['home'] }}

{{ pillar['ssl']['certs'] }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ pillar['ssl']['home'] }}

{{ pillar['ssl']['keys'] }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ pillar['ssl']['home'] }}

{% if not 'vpnserver' in pillar['net']['hosts'][grains['id']] %}
{{ pillar['ssl']['keys'] }}/{{ grains['nodename'] }}.key:
  file.managed:
    - source: salt://keys/{{ grains['nodename'] }}.key
    - user: root
    - group: root
    - mode: 640
    - makedirs: True

{{ pillar['ssl']['certs'] }}/{{ grains['nodename'] }}.crt:
  file.managed:
    - source: salt://certs/{{ grains['nodename'] }}.crt
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
{% endif %}

{{ pillar['ssl']['ca_crt'] }}:
  file.managed:
    - source: salt://ca/ca.crt
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
