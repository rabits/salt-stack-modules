#
# I2P - i2p network access
#

include:
  - tinyproxy

i2p-repo:
  pkgrepo.managed:
   - ppa: i2p-maintainers/i2p
   - required_in:
     - pkg: i2p

i2p:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: i2p
