#
# LightDM display manager
#

lightdm:
  pkg:
    - installed
  service.running:
    # We do not need to restart lightdm if file changes
    - require:
      - file: /etc/lightdm/lightdm.conf

/etc/lightdm/login.sh:
  file.managed:
    - source: salt://lightdm/login.sh
    - mode: 755
    - user: root
    - group: root
    - replace: False

/etc/lightdm/lightdm.conf:
  file.managed:
    - source: salt://lightdm/lightdm.conf
    - mode: 644
    - user: root
    - group: root
    - require:
      - pkg: lightdm
      - file: /etc/lightdm/login.sh
