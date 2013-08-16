#
# Crontab encrypted lvm backup
#

# To use backup you must setup environment:
#  1. Create key file /home/backup.key (don't forget save password into encrypted storage and wallet)
#    # tr -dc A-Za-z0-9_ < /dev/urandom | head -c 64 > /home/backup.key
#  2. Encrypt selected partition:
#    # cryptsetup luksFormat /dev/mapper/vg-backup /home/backup.key
#  3. Open encrypted device:
#    # cryptsetup -d /home/backup.key luksOpen /dev/mapper/vg-backup backup_crypt
#  4. Create volume group "backup" into encrypted partition
#    # vgcreate backup /dev/mapper/backup_crypt
#  5. Create 2 logical volumes into volume group:
#    # lvcreate -l 32767 -n daily backup && lvcreate -l 32768 -n weekly backup
#  6. Format this partitions:
#    # mkfs.ext4 /dev/backup/daily && mkfs.ext4 /dev/backup/weekly
#  7. Detach partitions:
#    # vgchange -a n backup
#    # cryptsetup luksClose backup_crypt
#  8. Write nodename with parameters into pillar/backup.sls

{% if grains['nodename'] in pillar['backup'] %}
include:
  - rsync
  - lvm
  - cryptsetup

/usr/local/bin/backup.sh:
  file.managed:
    - source: salt://backup/backup.sh.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 750
    - require:
      - pkg: rsync
      - pkg: lvm
      - pkg: cryptsetup

/usr/local/bin/backup.sh 2>&1 | /usr/bin/logger -t BACKUP:
  cron.present:
    - user: root
    - minute: 0
    - hour: 22
    - require:
      - file: /usr/local/bin/backup.sh
{% endif %}
