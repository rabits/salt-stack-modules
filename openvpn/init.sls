#
# OpenVPN private network
#

openvpn:
  pkg:
    - installed
  service.running:
    - enable: True

