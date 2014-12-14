#
# SSH client & server
#

ssh:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: ssh

sshfs:
  pkg.installed

/etc/ssh/sshd_config:
  file.managed:
    - source: salt://ssh/sshd_config
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: True
    - require:
      - pkg: ssh
    - watch_in:
      - service: ssh

sftpusers:
  group.present

sftp:
  group:
    - present
  user.present:
    - gid_from_name: True
    - system: True
    - createhome: False
    - groups:
      - sftpusers
    - require:
      - group: sftp
      - group: sftpusers

/srv/sftp:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - require:
      - pkg: ssh

/srv/sftp/sftp:
  file.directory:
    - user: root
    - group: root
    - mode: 755

/home/sftp:
  file.directory:
    - user: sftp
    - group: sftp
    - mode: 750
    - require:
      - user: sftp
