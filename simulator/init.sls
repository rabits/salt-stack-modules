#
# Simulator USB interface
#

/etc/udev/rules.d/60-simulator-usb.rules:
  file.managed:
    - source: salt://simulator/udev.rules
    - user: root
    - group: root
    - mode: 644
