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
    - name: debootstrap --variant=minbase --arch=amd64 --include=xserver-xorg,libfontconfig1,libqtcore4,libxcursor1,libxfixes3,libxxf86vm1,xinit,libc6-i386,dkms,lib32gcc1,linux-headers-generic,python,curl,linux-sound-base,alsa-utils,software-properties-common raring /srv/schroot/radeon 'http://archive.ubuntu.com/ubuntu/'
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

schroot-radeon-install-fglrx:
  cmd.wait:
    - name: mount --bind /dev /srv/schroot/radeon/dev && chroot /srv/schroot/radeon sh -cx 'dpkg --add-architecture i386 ; echo "deb http://archive.ubuntu.com/ubuntu raring main restricted universe multiverse" > /etc/apt/sources.list ; add-apt-repository -y ppa:xorg-edgers/ppa ; apt-get update ; apt-get install -y --no-install-recommends fglrx-13 x2x' ; umount /srv/schroot/radeon/dev
    - watch:
      - cmd: schroot-radeon-debootstrap

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

/srv/schroot/radeon/etc/asound.conf:
  file.managed:
    - source: salt://schroot/radeon.asound.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: schroot-radeon-debootstrap
