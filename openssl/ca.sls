#
# SSL CA
#
# Create CA:
#   # openssl req -config /srv/ssl/ca/ca.config -new -x509 -days $((366*20)) -keyout /srv/ssl/ca/ca.key -out /srv/ssl/ca/ca.crt -subj "/CN=CA"
#
# Create server signed cert:
#   # openssl req -config /srv/ssl/ca/ca.config -extensions server -new -newkey 'rsa:2048' -nodes -keyout {{ pillar['ssl']['keys'] }}/OUTPUT.key -out {{ pillar['ssl']['csrs'] }}/OUTPUT.csr -subj '/CN=*.somesite.org'
#   # openssl ca -config /srv/ssl/ca/ca.config -extensions server -in /srv/ssl/csrs/INPUT.csr -out /srv/ssl/certs/OUTPUT.crt -batch
#
# Create client signed cert:
#   # openssl req -config /srv/ssl/ca/ca.config -days 365 -new -newkey 'rsa:2048' -nodes -keyout {{ pillar['ssl']['keys'] }}/OUTPUT.key -out {{ pillar['ssl']['csrs'] }}OUTPUT.csr -subj '/CN=*.somesite.org'
#   # openssl ca -config /srv/ssl/ca/ca.config -days 365 -in /srv/ssl/csrs/INPUT.csr -out /srv/ssl/certs/OUTPUT.crt -batch
#
# Revoke certificate:
#   # openssl ca -config /srv/ssl/ca/ca.config -revoke CERTIFICATE.crt
# Create CRL:
#   # openssl ca -config /srv/ssl/ca/ca.config -gencrl -out /srv/ssl/ca/crl.pem
#
# Create pcks12 with cert & key:
#   # openssl pkcs12 -config /srv/ssl/ca/ca.config -export -in INPUT.crt -inkey INPUT.key -certfile /srv/ssl/ca/ca.crt -out OUTPUT.p12 -passout pass:PASSWORD

include:
  - openssl

{{ pillar['ssl']['ca_config'] }}:
  file.managed:
    - source: salt://openssl/ca.config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640
    - require:
      - file: {{ pillar['ssl']['ca'] }}

{{ pillar['ssl']['ca'] }}/db:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - file: {{ pillar['ssl']['ca'] }}

{{ pillar['ssl']['ca'] }}/db/index.txt:
  file.managed:
    - user: root
    - group: root
    - mode: 640
    - require:
      - file: {{ pillar['ssl']['ca'] }}/db

{{ pillar['ssl']['ca'] }}/db/serial:
  file.managed:
    - user: root
    - group: root
    - mode: 640
    - replace: False
    - contents: '01'
    - require:
      - file: {{ pillar['ssl']['ca'] }}/db

{{ pillar['ssl']['newcerts'] }}:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - file: {{ pillar['ssl']['home'] }}

openssl dhparam -out {{ pillar['ssl']['home'] }}/dh2048.pem 2048:
  cmd.run:
    - unless: test -f {{ pillar['ssl']['home'] }}/dh2048.pem
    - require:
      - pkg: openssl
      - file: {{ pillar['ssl']['home'] }}

{{ pillar['ssl']['csrs'] }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ pillar['ssl']['home'] }}

{{ pillar['ssl']['crls'] }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ pillar['ssl']['home'] }}

{% for host, args in pillar['net']['hosts'].items() %}
openssl req -config {{ pillar['ssl']['ca_config'] }} {% if 'server' in args %}-extensions server{% else %}-days 365{% endif %} -new -newkey 'rsa:2048' -nodes -keyout {{ pillar['ssl']['keys'] }}/{{ host }}.key -out {{ pillar['ssl']['csrs'] }}/{{ host }}.csr -subj '/CN={{ host }}':
  cmd.run:
    - unless: test -f {{ pillar['ssl']['csrs'] }}/{{ host }}.csr -o -f {{ pillar['ssl']['certs'] }}/{{ host }}.crt
    - require:
      - pkg: openssl
      - file: {{ pillar['ssl']['ca_config'] }}
    - require_in:
      - file: /etc/openvpn/server.conf
{% endfor %}
