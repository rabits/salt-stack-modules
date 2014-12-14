#
# OpenVPN - virtual private network client
#
# Notice: Disabled by default - to enable add net:hosts:<id>:vpn: client
#

{% import 'openssl/vars.sls' as ssl with context %}
{% import 'openvpn/vars.sls' as vpn with context %}

include:
  - openssl

openvpn:
  pkg:
    - installed
  service:
    {%- if vpn.autorun != 'no' %}
    - running
    {%- else %}
    - disabled
    {%- endif %}

{% if vpn.instance != 'none' -%}
/etc/openvpn/{{ vpn.instance }}.conf:
  file.managed:
    - source: salt://openvpn/{{ vpn.instance }}.conf.jinja
    - user: root
    - group: root
    - mode: 640
    - template: jinja
    - context:
      vpn_host: {{ vpn.host }}
      vpn_port: {{ vpn.port }}
      vpn_cert: {{ vpn.cert }}
      vpn_key: {{ vpn.key }}
      vpn_ta: {{ vpn.ta }}
      vpn_ccd: {{ vpn.ccd }}
      vpn_ip: {{ vpn.ip }}
      vpn_net: {{ vpn.net }}
      vpn_mask: {{ vpn.mask }}
      ssl_ca_crt: {{ ssl.ca_crt }}
      ssl_cert: {{ ssl.cert }}
      ssl_key: {{ ssl.key }}
      ssl_dh: {{ ssl.dh }}
    - require:
      - pkg: openvpn
    - watch_in:
      - service: openvpn
{%- endif %}

/etc/default/openvpn:
  file.replace:
    - pattern: '^AUTOSTART=.+$'
    - repl: AUTOSTART="{{ vpn.instance }}"
    - append_if_not_found: True
    - watch_in:
      - service: openvpn
    - require:
      - pkg: openvpn
    {%- if vpn.instance != 'none' %}
      - file: /etc/openvpn/{{ vpn.instance }}.conf
    {%- endif %}

{{ vpn.ta }}:
  file.managed:
    {%- if vpn.instance != 'server' %}
    - source: salt://openvpn_ta.key
    - group: root
    {%- else %}
    - group: salt-stack
    {% endif %}
    - user: root
    - mode: 640
    - makedirs: True
    - watch_in:
      - service: openvpn
