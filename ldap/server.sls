#
# LDAP server - central authentificator
#

include:
  - ldap

/etc/default/slapd:
  file.managed:
    - source: salt://ldap/default-slapd
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: slapd
    - watch_in:
      - service: slapd

slapd:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: ldap-utils
