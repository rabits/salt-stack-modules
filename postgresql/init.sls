#
# PostgreSQL relation database
#

{% set version="9.1" %}

postgresql:
  pkg:
    - latest
    - names:
      - postgresql-{{ version }}
      - postgresql-client-{{ version }}
  service.running:
    - reload: True
    - watch:
      - pkg: postgresql

/etc/postgresql/{{ version }}/main/postgresql.conf:
  file.managed:
    - source: salt://postgresql/postgresql.conf
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql

/etc/postgresql/{{ version }}/main/pg_hba.conf:
  file.managed:
    - source: salt://postgresql/pg_hba.conf
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql
