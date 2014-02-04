#
# OpenVPN private network
#

include:
  - openssl

openvpn:
  pkg:
    - installed
  service.running:
    - enable: True

