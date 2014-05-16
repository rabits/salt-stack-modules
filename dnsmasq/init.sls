#
# Dnsmasq - DNS & DHCP service
#

dnsmasq:
  pkg:
    - installed
  service.running:
    - watch:
      - file: /etc/hosts
    - require:
      - pkg: dnsmasq

/etc/dnsmasq.conf:
  file.managed:
    - source: salt://dnsmasq/dnsmasq.conf.jinja
    - template: jinja
    - mode: 0644
    - user: root
    - group: root
    - require:
      - pkg: dnsmasq
    - watch_in:
      - service: dnsmasq

/etc/resolv.conf:
  file.managed:
    - mode: 0644
    - user: root
    - group: root
    - contents: "nameserver 127.0.0.1\n"
    - require:
      - pkg: dnsmasq
      - service: dnsmasq
