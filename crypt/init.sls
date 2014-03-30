#
# Crypt partitions
# Decrypt partitions on login
#
# Do not forget to change configuration in ../../pillar/crypt.sls
#
# HowTO:
#  1. Prepare home partition
#    # cryptsetup luksFormat /dev/md1
#  2. Open encrypted device:
#    # cryptsetup luksOpen /dev/md1 home
#  3. Format this partitions:
#    # mkfs.ext4 /dev/mapper/home
#  4. Mount partition in some place
#    # mount /dev/mapper/home /mnt
#  5. Copy homedir with your user
#    # cp -a /home/USER /mnt
#  6. Umount & detach partition
#    # umount /dev/mapper/home && cryptsetup luksClose /dev/mapper/home
#

include:
 - cryptsetup

libpam-mount:
  pkg.installed

/etc/security/pam_mount.conf.xml:
  file.managed:
    - source: salt://crypt/pam_mount.conf.xml.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: libpam-mount
