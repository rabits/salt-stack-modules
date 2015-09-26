#
# Tor - onion network access
#

include:
  - polipo
  - tinyproxy

tor:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: tor
