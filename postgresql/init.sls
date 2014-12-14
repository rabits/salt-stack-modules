#
# PostgreSQL relation database
#

{% set version = salt['pillar.get']('postgresql:'+grains['id']+':version', '9.3') %}
{% set listen = salt['pillar.get']('postgresql:'+grains['id']+':listen', 'localhost') %}
{% set access = salt['pillar.get']('postgresql:'+grains['id']+':access', '127.0.0.1/32') %}

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
    - source: salt://postgresql/postgresql.conf.jinja
    - template: jinja
    - context:
      version: {{ version }}
      listen: {{ listen }}
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql

/etc/postgresql/{{ version }}/main/pg_hba.conf:
  file.managed:
    - source: salt://postgresql/pg_hba.conf.jinja
    - template: jinja
    - context:
      access: {{ access }}
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql
