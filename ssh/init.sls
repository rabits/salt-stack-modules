#
# SSH client & server
#

ssh:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: ssh
      - file: /etc/ssh/sshd_config

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
