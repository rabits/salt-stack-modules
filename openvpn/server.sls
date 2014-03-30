#
# OpenVPN - master
#
# Do not forget to sign opencsr!
#

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

{% set var_vpn_ip = salt['pillar.get']('openvpn:ip', '192.168.0.1') %}
{% set var_vpn_net = salt['pillar.get']('openvpn:net', '192.168.0.0') %}
{% set var_vpn_mask = salt['pillar.get']('openvpn:mask', '255.255.255.0') %}

openvpn --genkey --secret {{ var_vpn_ta }}:
  cmd.run:
    - unless: test -f {{ var_vpn_ta }}
    - require:
      - pkg: openvpn
    - require_in:
      - file: /etc/openvpn/server.conf
      - file: {{ var_vpn_ta }}

{{ var_vpn_ta }}:
  file.managed:
    - user: root
    - group: salt-stack
    - mode: 640
    - create: False

openssl req -config {{ var_ca_config }} -extensions server -new -newkey 'rsa:2048' -nodes -keyout {{ var_vpn_key }} -out {{ var_vpn_csr }} -subj "/CN=vpn":
  cmd.run:
    - unless: test -f {{ var_vpn_key }}
    - require:
      - pkg: openssl
      - file: {{ var_ca_config }}
    - require_in:
      - file: /etc/openvpn/server.conf

/etc/openvpn/server.conf:
  file.managed:
    - source: salt://openvpn/server.conf.jinja
    - user: root
    - group: root
    - mode: 640
    - template: jinja
    - context:
      var_vpn_port: {{ var_vpn_port }}
      var_vpn_cert: {{ var_vpn_cert }}
      var_vpn_key: {{ var_vpn_key }}
      var_vpn_ta: {{ var_vpn_ta }}
      var_vpn_ccd: {{ var_vpn_ccd }}
      var_vpn_ip: {{ var_vpn_ip }}
      var_vpn_net: {{ var_vpn_net }}
      var_vpn_mask: {{ var_vpn_mask }}
      var_ca_crt: {{ var_ca_crt }}
      var_ssl_home: {{ var_ssl_home }}
      var_certs: {{ var_certs }}
      var_keys: {{ var_keys }}
      var_dh: {{ var_dh }}
    - require:
      - pkg: openvpn
    - watch_in:
      - service: openvpn

/etc/default/openvpn:
  file.append:
    - text:
      - AUTOSTART="server"
    - require:
      - file: /etc/openvpn/server.conf
    - watch_in:
      - service: openvpn

{{ var_vpn_ccd }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755

{% for host, args in salt['pillar.get']('net:hosts', {}).items() %}{% if not 'vpnserver' in args %}
{{ var_vpn_ccd }}/{{ host }}:
  file.managed:
    - contents: "ifconfig-push {{ args['ip'] }} {{ var_vpn_ip }}{% if 'route' in args %}\niroute {{ args['route'] }} {{ var_vpn_mask }}{% endif %}\n"
    - user: root
    - group: root
    - mode: 644
{% endif %}{% endfor %}
