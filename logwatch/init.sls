#
# Awesome - window manager
#

logwatch:
  pkg.installed

/etc/logwatch/conf/logwatch.conf:
  file.managed:
    - source: salt://logwatch/logwatch.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: logwatch

/var/cache/logwatch:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - pkg: logwatch

/etc/cron.weekly/00logwatch:
  file.rename:
    - source: /etc/cron.daily/00logwatch
    - require:
      - pkg: logwatch
