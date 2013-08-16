#
# Razer Hydra controller drivers
#

/etc/udev/rules.d/99-sixense-libusb.rules:
  file.managed:
    - source: salt://razerhydra/udev.rules
    - user: root
    - group: root
    - mode: 644
