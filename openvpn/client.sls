#
# OpenVPN - master
#
# Do not forget to sign openvpn.csr!
#
# Notice: vpnserver master will be skipped
#

{% if not 'vpnserver' in pillar['net']['hosts'][grains['id']] %}
include:
  - openssl
  - openvpn

{{ pillar['ssl']['home'] }}/openvpn_ta.key:
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
