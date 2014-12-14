#
# Salt client
#

# Salt-Stack repo
salt-stack-repo:
  pkgrepo.managed:
   - ppa: saltstack/salt
   - required_in:
     - pkg: salt-minion

/etc/init/salt-minion.conf:
  file.sed:
    - before: '#'
    - after: ''
    - limit: '^#respawn$'

salt-minion:
  pkg:
    - installed
  service:
    - running

/etc/salt/minion:
  file.managed:
    - source: salt://salt/minion.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600
