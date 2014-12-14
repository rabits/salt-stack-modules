#
# LDAP - central authentificator
#

ldap-packages:
  pkg.installed:
    - pkgs:
      - slapd
      - ldap-utils

/etc/default/slapd:
  file.managed:
    - source: salt://ldap/default-slapd
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: ldap-packages
    - watch_in:
      - service: slapd

slapd:
  service.running:
    - require:
      - pkg: ldap-packages
