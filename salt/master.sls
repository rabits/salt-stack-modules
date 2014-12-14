#
# Salt master server
#

include:
  - salt

salt-stack:
  user.present:
    - home: /srv/salt
    - shell: /bin/nologin
    - system: True

salt-master:
  pkg:
    - installed
  service.running:
    - watch:
      - pkg: salt-master
      - file: /etc/salt/master

/etc/salt/master:
  file.managed:
    - source: salt://salt/master.jinja
    - template: jinja
    - user: root
    - group: salt-stack
    - mode: 640
    - require:
      - pkg: salt-master

/etc/salt/pki/master:
  file.directory:
    - user: salt-stack
    - require:
      - pkg: salt-master
    - recurse:
      - user
