#
# OpenVPN - master
#
# Do not forget to sign openvpn.csr!
#
# Notice: vpnserver master will be skipped
#

{% if not 'vpnserver' in salt['pillar.get']('net:hosts:%s'|format(grains['nodename']), {}) %}
include:
  - openvpn

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

{% set var_vpn_host = salt['pillar.get']('openvpn:host', 'localhost') %}
{% set var_vpn_port = salt['pillar.get']('openvpn:port', '1194') %}
{% set var_vpn_ccd  = salt['pillar.get']('openvpn:ccd', '/etc/openvpn/ccd') %}

{% set var_vpn_ta   = var_ssl_home + '/openvpn_ta.key' %}
{% set var_vpn_key  = var_keys + '/openvpn.key' %}
{% set var_vpn_cert = var_certs + '/openvpn.crt' %}
{% set var_vpn_csr  = var_csrs + '/openvpn.csr' %}

{{ var_vpn_ta }}:
  file.managed:
    - source: salt://openvpn_ta.key
    - user: root
    - group: root
    - mode: 640
    - makedirs: True
    - watch_in:
      - service: openvpn

/etc/openvpn/client.conf:
  file.managed:
    - source: salt://openvpn/client.conf.jinja
    - user: root
    - group: root
    - mode: 640
    - template: jinja
    - context:
      var_vpn_host: {{ var_vpn_host }}
      var_vpn_port: {{ var_vpn_port }}
      var_vpn_ta: {{ var_vpn_ta }}
      var_ca_crt: {{ var_ca_crt }}
      var_certs: {{ var_certs }}
      var_keys: {{ var_keys }}
    - require:
      - pkg: openvpn
    - watch_in:
      - service: openvpn

/etc/default/openvpn:
  file.append:
    - text:
      - AUTOSTART="client"
    - require:
      - file: /etc/openvpn/client.conf
    - watch_in:
      - service: openvpn
{% endif %}
