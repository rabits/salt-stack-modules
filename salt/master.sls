#
# Salt master server
#

include:
  - salt

salt-stack:
  user.present:
    - home: /srv/salt
    - shell: /bin/nologin

salt-master:
  pkg:
    - installed
  service.running:
    - watch:
      - pkg: salt-master
      - file: /etc/salt/master

/etc/salt/master:
  file.managed:
    - source: salt://salt/master
    - user: salt-stack
    - group: root
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

/var/cache/salt/master:
  file.directory:
    - user: salt-stack
    - require:
      - pkg: salt-master
    - recurse:
      - user
