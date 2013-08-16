#
# Network configuration
#

/etc/hosts:
  file.managed:
    - source: salt://net/hosts.jinja
    - template: jinja
