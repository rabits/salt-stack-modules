#
# OpenSSL crypto library
#

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

openssl:
  pkg.installed

{{ var_ssl_home }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755

{{ var_ca }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ var_ssl_home }}

{{ var_certs }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ var_ssl_home }}

{{ var_keys }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: {{ var_ssl_home }}

{% if not 'vpnserver' in salt['pillar.get']('net:hosts:%s'|format(grains['nodename']), {}) %}
{{ var_keys }}/{{ grains['nodename'] }}.key:
  file.managed:
    - source: salt://keys/{{ grains['nodename'] }}.key
    - user: root
    - group: root
    - mode: 640
    - makedirs: True

{{ var_certs }}/{{ grains['nodename'] }}.crt:
  file.managed:
    - source: salt://certs/{{ grains['nodename'] }}.crt
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
{% endif %}

{{ var_ca_crt }}:
  file.managed:
    - source: salt://ca/ca.crt
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
