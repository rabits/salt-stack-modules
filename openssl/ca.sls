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

{% set var_ssl_home   = salt['pillar.get']('ssl:home', '/srv/ssl') %}
{% set var_ca         = salt['pillar.get']('ssl:ca', var_ssl_home+'/ca') %}
{% set var_ca_key     = salt['pillar.get']('ssl:ca_key', var_ca+'/ca.key') %}
{% set var_ca_crt     = salt['pillar.get']('ssl:ca_crt', var_ca+'/ca.crt') %}
{% set var_ca_config  = salt['pillar.get']('ssl:ca_config', var_ca+'/ca.config') %}
{% set var_crl        = salt['pillar.get']('ssl:crl', var_ca+'/crl.pem') %}
{% set var_keys       = salt['pillar.get']('ssl:keys', var_ssl_home+'/keys') %}
{% set var_certs      = salt['pillar.get']('ssl:certs', var_ssl_home+'/certs') %}
{% set var_newcerts   = salt['pillar.get']('ssl:newcerts', var_ssl_home+'/newcerts') %}
{% set var_csrs       = salt['pillar.get']('ssl:csrs', var_ssl_home+'/csrs') %}
{% set var_crls       = salt['pillar.get']('ssl:crls', var_ssl_home+'/crls') %}
{% set var_dh         = var_ssl_home + '/dh2048.pem' %}

{{ var_ca_config }}:
  file.managed:
    - source: salt://openssl/ca.config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640
    - context:
      var_ca: {{ var_ca }}
      var_ca_key: {{ var_ca_key }}
      var_ca_crt: {{ var_ca_crt }}
      var_crl: {{ var_crl }}
      var_certs: {{ var_certs }}
      var_newcerts: {{ var_newcerts }}
      var_crls: {{ var_crls }}
    - require:
      - file: {{ var_ca }}

{{ var_ca }}/db:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - file: {{ var_ca }}

{{ var_ca }}/db/index.txt:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: {{ var_ca }}/db

{{ var_ca }}/db/serial:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - replace: False
    - contents: '01'
    - require:
      - file: {{ var_ca }}/db

{{ var_newcerts }}:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - file: {{ var_ssl_home }}

openssl dhparam -out {{ var_dh }} 2048:
  cmd.run:
    - unless: test -f {{ var_dh }}
    - require:
      - pkg: openssl
      - file: {{ var_ssl_home }}

{{ var_csrs }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ var_ssl_home }}

{{ var_crls }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ var_ssl_home }}

{% for host, args in salt['pillar.get']('net:hosts', {}).items() %}
openssl req -config {{ var_ca_config }} {% if 'server' in args %}-extensions server{% else %}-days 365{% endif %} -new -newkey 'rsa:2048' -nodes -keyout {{ var_keys }}/{{ host }}.key -out {{ var_csrs }}/{{ host }}.csr -subj '/CN={{ host }}':
  cmd.run:
    - unless: test -f {{ var_csrs }}/{{ host }}.csr -o -f {{ var_certs }}/{{ host }}.crt
    - require:
      - pkg: openssl
      - file: {{ var_ca_config }}
    - require_in:
      - file: /etc/openvpn/server.conf
{% endfor %}
