#
# SChroot - simple chroot for user
#

schroot-pkgs:
  pkg.installed:
    - pkgs:
      - schroot
      - debootstrap

/srv/schroot:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - pkg: schroot-pkgs

debootstrap --variant=buildd --arch=amd64 raring /srv/schroot/raring64 'http://archive.ubuntu.com/ubuntu/':
  cmd.run:
    - unless: test -d /srv/schroot/raring64
    - require:
      - pkg: schroot-pkgs

/etc/schroot/chroot.d/raring64.conf:
  file.managed:
    - source: salt://schroot/schroot.conf.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: True
    - require:
      - pkg: schroot-pkgs

/etc/schroot/buildd/fstab:
  file.managed:
    - source: salt://schroot/fstab
    - require:
      - pkg: schroot-pkgs

/etc/pam.d/schroot:
  file.managed:
    - source: salt://schroot/schroot.pam
    - require:
      - pkg: schroot-pkgs
