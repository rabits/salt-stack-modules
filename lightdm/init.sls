#
# LightDM display manager
#

lightdm:
  pkg.installed

/etc/lightdm/lightdm.conf:
  file.append:
    - text:
      - allow-guest=false
      - greeter-allow-guest=false
      - greeter-show-remote-login=false
    - require:
      - pkg: lightdm
