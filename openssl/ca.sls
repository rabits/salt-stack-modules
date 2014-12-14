#
# SSL CA
#
# Create CA:
#   # openssl req -config /srv/ssl/ca/ca.config -new -x509 -days $((366*20)) -keyout /srv/ssl/ca/ca.key -out /srv/ssl/ca/ca.crt -subj "/CN=CA"
#
# Create server signed cert:
#   # openssl req -config /srv/ssl/ca/ca.config -extensions server -new -newkey 'rsa:2048' -nodes -keyout /srv/ssl/keys/OUTPUT.key -out /srv/ssl/csrs/OUTPUT.csr -subj '/CN=*.somesite.org'
#   # openssl ca -config /srv/ssl/ca/ca.config -extensions server -in /srv/ssl/csrs/INPUT.csr -out /srv/ssl/certs/OUTPUT.crt -batch
#
# Create client signed cert:
#   # openssl req -config /srv/ssl/ca/ca.config -days 365 -new -newkey 'rsa:2048' -nodes -keyout /srv/ssl/keys/OUTPUT.key -out /srv/ssl/csrs/OUTPUT.csr -subj '/CN=*.somesite.org'
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

{% import 'openssl/vars.sls' as ssl with context %}

{{ ssl.ca_config }}:
  file.managed:
    - source: salt://openssl/ca.config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640
    - context:
      ssl_ca: {{ ssl.ca }}
      ssl_ca_key: {{ ssl.ca_key }}
      ssl_ca_crt: {{ ssl.ca_crt }}
      ssl_crl: {{ ssl.crl }}
      ssl_certs: {{ ssl.certs }}
      ssl_newcerts: {{ ssl.newcerts }}
      ssl_crls: {{ ssl.crls }}
    - require:
      - file: {{ ssl.ca }}

{{ ssl.ca }}/db:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - file: {{ ssl.ca }}

{{ ssl.ca }}/db/index.txt:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: {{ ssl.ca }}/db

{{ ssl.ca }}/db/serial:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - replace: False
    - contents: '01'
    - require:
      - file: {{ ssl.ca }}/db

{{ ssl.newcerts }}:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - file: {{ ssl.home }}

openssl dhparam -out {{ ssl.dh }} 2048:
  cmd.run:
    - unless: test -f {{ ssl.dh }}
    - require:
      - pkg: openssl
      - file: {{ ssl.home }}

{{ ssl.csrs }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ ssl.home }}

{{ ssl.crls }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ ssl.home }}

/usr/local/bin/certscheck.sh:
  file.managed:
    - source: salt://openssl/certscheck.sh.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - context:
      ssl_ca_crt: {{ ssl.ca_crt }}
      ssl_certs: {{ ssl.certs }}
    - require:
      - file: {{ ssl.certs }}

/usr/local/bin/certscheck.sh 2>&1 | /usr/bin/logger -t CERTSCHECK:
  cron.present:
    - user: root
    - minute: 0
    - hour: 23
    - require:
      - file: /usr/local/bin/certscheck.sh

{% for host, args in salt['pillar.get']('net:hosts', {}).items() %}
{% set file_name = "internal_" + salt['additional.inverse'](host) %}
openssl req -config {{ ssl.ca_config }} {% if 'server' in args %}-extensions server{% else %}-days 365{% endif %} -new -newkey 'rsa:2048' -nodes -keyout {{ ssl.keys }}/{{ file_name }}.key -out {{ ssl.csrs }}/{{ file_name }}.csr -subj '/CN={{ host }}':
  cmd.run:
    - unless: test -f {{ ssl.csrs }}/{{ file_name }}.csr -o -f {{ ssl.certs }}/{{ file_name }}.crt
    - require:
      - pkg: openssl
      - file: {{ ssl.ca_config }}
    - require_in:
      - file: {{ ssl.keys }}/{{ file_name }}.key

{{ ssl.keys }}/{{ file_name }}.key:
  file.managed:
    - user: root
    - group: salt-stack
    - mode: 640
{% endfor %}
