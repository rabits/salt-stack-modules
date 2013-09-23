#
# SChroot radeon runplace
#
# You need:
#  - Install fglrx to master system and disable it by using intel drivers
#  - Init ati in radeon schroot
#    # aticonfig --init
#  - Copy libs in radeon schroot (maybe bug in ati?)
#    # cp -a /usr/lib/x86_64-linux-gnu/xorg/extra-modules/modules/* /usr/lib/xorg/modules/

include:
  - schroot

schroot-radeon-debootstrap:
  cmd.run:
    - name: debootstrap --variant=minbase --arch=amd64 --include=xserver-xorg,libfontconfig1,libqtcore4,libxcursor1,libxfixes3,libxxf86vm1,xinit,libc6-i386,dkms,lib32gcc1,linux-headers,python,curl,x2x raring /srv/schroot/radeon 'http://archive.ubuntu.com/ubuntu/'
    - unless: test -d /srv/schroot/radeon
    - require:
      - pkg: schroot-pkgs
      - file: /srv/schroot

/etc/schroot/chroot.d/radeon.conf:
  file.managed:
    - source: salt://schroot/radeon.conf.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: True
    - require:
      - pkg: schroot-pkgs

/srv/schroot/radeon/root/fglrx.deb:
  file.managed:
    - source: salt://fglrx/fglrx_12.104-0ubuntu1_amd64.deb
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: schroot-radeon-debootstrap

schroot-radeon-install-fglrx:
  cmd.wait:
    - name: mount --bind /dev /srv/schroot/radeon/dev && chroot /srv/schroot/radeon dpkg -i /root/fglrx.deb ; umount /srv/schroot/radeon/dev
    - watch:
      - file: /srv/schroot/radeon/root/fglrx.deb

/srv/schroot/radeon/etc/X11/xorg.conf:
  file.managed:
    - source: salt://schroot/radeon.xorg.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: schroot-radeon-debootstrap

/srv/schroot/radeon/etc/X11/Xwrapper.config:
  file.managed:
    - source: salt://schroot/radeon.xwrapper.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: schroot-radeon-debootstrap

