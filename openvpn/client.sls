#
# OpenVPN - master
#
# Do not forget to sign openvpn.csr!
#
# Notice: vpnserver master will be skipped
#

{% if not 'vpnserver' in salt['pillar.get']('net:hosts:%s'|format(grains['nodename']), {}) %}

{% import 'openssl/vars.sls' as ssl with context %}
{% import 'openvpn/vars.sls' as vpn with context %}

include:
  - openvpn

{{ vpn.ta }}:
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
      vpn_host: {{ vpn.host }}
      vpn_port: {{ vpn.port }}
      vpn_ta: {{ vpn.ta }}
      ssl_ca_crt: {{ ssl.ca_crt }}
      ssl_certs: {{ ssl.certs }}
      ssl_keys: {{ ssl.keys }}
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
