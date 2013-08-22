#
# PgSQL php5 module
#

php5-pgsql:
  pkg.installed:
    - require:
      - pkg: php5
    - watch_in:
      - service: php5
