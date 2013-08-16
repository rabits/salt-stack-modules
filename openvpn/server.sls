#
# OpenVPN - master
#
# Do not forget to sign openvpn.csr!
#

include:
  - openssl
  - openvpn

openvpn --genkey --secret {{ pillar['ssl']['home'] }}/openvpn_ta.key:
  cmd.run:
    - unless: test -f {{ pillar['ssl']['home'] }}/openvpn_ta.key
    - require:
      - pkg: openvpn
    - require_in:
      - file: /etc/openvpn/server.conf
      - file: {{ pillar['ssl']['home'] }}/openvpn_ta.key

{{ pillar['ssl']['home'] }}/openvpn_ta.key:
  file.managed:
    - user: root
    - group: salt-stack
    - mode: 640
    - create: False

openssl req -config {{ pillar['ssl']['ca_config'] }} -extensions server -new -newkey 'rsa:2048' -nodes -keyout {{ pillar['ssl']['keys'] }}/openvpn.key -out {{ pillar['ssl']['csrs'] }}/openvpn.csr -subj "/CN=vpn":
  cmd.run:
    - unless: test -f {{ pillar['ssl']['keys'] }}/openvpn.key
    - require:
      - pkg: openssl
      - file: {{ pillar['ssl']['ca_config'] }}
    - require_in:
      - file: /etc/openvpn/server.conf

/etc/openvpn/server.conf:
  file.managed:
    - source: salt://openvpn/server.conf.jinja
    - user: root
    - group: root
    - mode: 640
    - template: jinja
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

{{ pillar['openvpn']['ccd'] }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755

{% for host, args in pillar['net']['hosts'].items() %}{% if not 'vpnserver' in args %}
{{ pillar['openvpn']['ccd'] }}/{{ host }}:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: ifconfig-push {{ args['ip'] }} 255.255.255.0
{% endif %}{% endfor %}
