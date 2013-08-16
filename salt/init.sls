#
# Salt client
#

/etc/init/salt-minion.conf:
  file.sed:
    - before: '#'
    - after: ''
    - limit: '^#respawn$'

salt-minion:
  pkg:
    - installed
  service.running:
    - watch:
      - pkg: salt-minion
      - file: /etc/salt/minion
      - file: /etc/salt/grains
      - file: /etc/init/salt-minion.conf

/etc/salt/minion:
  file.managed:
    - source: salt://salt/minion.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600

/etc/salt/grains:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False
    - contents: 'roles: none'
