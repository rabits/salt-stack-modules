#
# Crypt partitions
# Decrypt partitions on login
#
# Do not forget to change configuration in ../../pillar/crypt.sls
#

/etc/security/pam_mount.conf.xml:
  file.managed:
    - source: salt://crypt/pam_mount.conf.xml.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
