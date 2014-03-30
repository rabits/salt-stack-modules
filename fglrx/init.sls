#
# FGLRX Radeon driver
#

fglrx:
  pkg.installed:
    - version: 2:9.000-0ubuntu3 # Lastest non-broken version for xorg 1.13

fglrx xorg.conf:
  cmd.run:
    - name: aticonfig --initial -f
    - unless: test -f /etc/X11/xorg.conf

amdconfig --set-pcs-str="DDX,EnableRandR12,FALSE":
  cmd.wait:
    - watch:
      - cmd: fglrx xorg.conf

aticonfig --set-pcs-u32=MCIL,HWUVD_H264Level51Support,1:
  cmd.wait:
    - watch:
      - cmd: fglrx xorg.conf

aticonfig --sync-vsync=on:
  cmd.wait:
    - watch:
      - cmd: fglrx xorg.conf

aticonfig --set-pcs-val=MCIL,DigitalHDTVDefaultUnderscan,0:
  cmd.wait:
    - watch:
      - cmd: fglrx xorg.conf

