#
# SSMTP local mail sender
#

ssmtp:
  pkg.installed

/etc/ssmtp/ssmtp.conf:
  file.managed:
    - source: salt://ssmtp/ssmtp.conf.jinja
    - template: jinja
    - user: root
    - group: mail
    - mode: 640
    - require:
      - pkg: ssmtp

/etc/ssmtp/revaliases:
  file.managed:
    - source: salt://ssmtp/revaliases.jinja
    - template: jinja
    - user: root
    - group: mail
    - mode: 644
    - require:
      - pkg: ssmtp
