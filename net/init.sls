#
# Network configuration
#

/etc/hosts:
  file.managed:
    - source: salt://net/hosts.jinja
    - template: jinja
    - mode: 0644
    - user: root
    - group: root
