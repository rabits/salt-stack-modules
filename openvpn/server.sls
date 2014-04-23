#
# OpenVPN - master
#
# Do not forget to sign opencsr!
#

{% import 'openssl/vars.sls' as ssl with context %}
{% import 'openvpn/vars.sls' as vpn with context %}

include:
  - openvpn
{%- if vpn.port <= 1024 %}
  - libcap2
{%- endif %}


openvpn --genkey --secret {{ vpn.ta }}:
  cmd.run:
    - unless: test -f {{ vpn.ta }}
    - require:
      - pkg: openvpn
    - require_in:
      - file: /etc/openvpn/server.conf
      - file: {{ vpn.ta }}

{{ vpn.ta }}:
  file.managed:
    - user: root
    - group: salt-stack
    - mode: 640
    - create: False

openssl req -config {{ ssl.ca_config }} -extensions server -new -newkey 'rsa:2048' -nodes -keyout {{ vpn.key }} -out {{ vpn.csr }} -subj "/CN=vpn":
  cmd.run:
    - unless: test -f {{ vpn.key }}
    - require:
      - pkg: openssl
      - file: {{ ssl.ca_config }}
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
      vpn_port: {{ vpn.port }}
      vpn_cert: {{ vpn.cert }}
      vpn_key: {{ vpn.key }}
      vpn_ta: {{ vpn.ta }}
      vpn_ccd: {{ vpn.ccd }}
      vpn_ip: {{ vpn.ip }}
      vpn_net: {{ vpn.net }}
      vpn_mask: {{ vpn.mask }}
      ssl_ca_crt: {{ ssl.ca_crt }}
      ssl_dh: {{ ssl.dh }}
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

{% if vpn.port <= 1024 -%}
setcap 'cap_net_bind_service=+ep' /usr/sbin/openvpn:
  cmd.run:
    - unless: getcap /usr/sbin/openvpn | grep -q 'cap_net_bind_service+ep'
    - require:
      - pkg: openssl
      - pkg: libcap2
    - require_in:
      - service: openvpn
{%- endif %}

{{ vpn.ccd }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755

{% for host, args in salt['pillar.get']('net:hosts', {}).items() %}{% if not 'vpnserver' in args %}
{{ vpn.ccd }}/{{ host }}:
  file.managed:
    - contents: "ifconfig-push {{ args['ip'] }} {{ vpn.ip }}{% if 'route' in args %}\niroute {{ args['route'] }} {{ vpn.mask }}{% endif %}\n"
    - user: root
    - group: root
    - mode: 644
{% endif %}{% endfor %}
