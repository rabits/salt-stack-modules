#
# OpenVPN - master
#
# Do not forget to sign openvpn.csr!
#

{% import 'openssl/vars.sls' as ssl with context %}
{% import 'openvpn/vars.sls' as vpn with context %}
{% from 'monit/macros.sls' import monit with context %}

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

openssl req -config {{ ssl.ca_config }} -extensions server -new -newkey 'rsa:2048' -nodes -keyout {{ vpn.key }} -out {{ vpn.csr }} -subj "/CN=vpn":
  cmd.run:
    - unless: test -f {{ vpn.key }}
    - require:
      - pkg: openssl
      - file: {{ ssl.ca_config }}
    - require_in:
      - file: /etc/openvpn/server.conf

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

{% for host, args in salt['pillar.get']('net:hosts', {}).items() %}{% if 'server' != args.vpn|default('none') %}
{{ vpn.ccd }}/{{ host }}:
  file.managed:
    - contents: |
        ifconfig-push {{ args['ip'] }} {{ vpn.ip }}{% if 'route' in args %}
        iroute {{ args['route'] }} {{ vpn.mask }}{% endif %}
    - user: root
    - group: root
    - mode: 644
{% endif %}{% endfor %}

{{ monit('openvpn', '', 'server') }}
