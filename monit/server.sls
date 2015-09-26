#
# MMonit - status server for monit
#

include:
  - nginx

{% import 'openssl/vars.sls' as ssl with context %}

{% set nginx_server_name = 'stat.' + salt['pillar.get']('net:main_domain', 'localhost') %}
{% set nginx_conf_name = salt['additional.inverse'](nginx_server_name) %}
{% set nginx_key = salt['pillar.get']('mmonit:ssl_key', ssl.key) %}
{% set nginx_cert = salt['pillar.get']('mmonit:ssl_cert', ssl.cert) %}

{% set dist_name = salt['pillar.get']('mmonit:dist_name', 'mmonit-3.5') %}
{% set dist = salt['pillar.get']('mmonit:dist', 'https://mmonit.com/dist/'+dist_name+'-linux-x64.tar.gz') %}
{% set dist_hash = salt['pillar.get']('mmonit:dist_hash', 'sha256=f12d30ec9e3320f4d3fe1ebe91bdf029db76cfebf3cbaefc563cb673b4d0aeb5') %}
{% set dist_dir = salt['pillar.get']('mmonit:dist_dir', '/srv/mmonit') %}
{% set username = salt['pillar.get']('mmonit:username', 'mmonit') %}

{% set service_port = salt['pillar.get']('mmonit:port', '8080') %}

{% set db_type = salt['pillar.get']('mmonit:db_type', 'sqlite3') %}
{% set db_path = salt['pillar.get']('mmonit:db_path', '../db/mmonit.db') %}
{% set db_name = salt['pillar.get']('mmonit:db_name', '') %}
{% set db_user = salt['pillar.get']('mmonit:db_user', '') %}
{% set db_password = salt['pillar.get']('mmonit:db_password', '') %}

{% set license_owner = salt['pillar.get']('mmonit:license_owner', '') %}
{% set license_data = salt['pillar.get']('mmonit:license_data', '') %}


{{ username }}:
  group.present:
    - system: True
  user.present:
    - gid_from_name: True
    - shell: /bin/sh
    - system: True
    - createhome: False
    - require:
      - group: {{ username }}

{%- if username != 'mmonit' %}

mmonit:
{%- endif %}
  service.running:
    - require:
      - user: {{ username }}
    - watch:
      - archive: mmonit-unpack

{{ dist_dir }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755

mmonit-unpack:
  archive.extracted:
    - name: {{ dist_dir }}
    - archive_user: root
    - archive_format: tar
    - source: '{{ dist }}'
    - source_hash: {{ dist_hash }}
    - if_missing: {{ dist_dir }}/{{ dist_name }}
    - keep: True
    - require:
      - user: {{ username }}

{{ dist_dir }}/current:
  file.symlink:
    - target: {{ dist_name }}
    - require:
      - file: {{ dist_dir }}
      - archive: mmonit-unpack
    - require_in:
      - service: mmonit

mmonit-subdirs:
  file.directory:
    - names:
      - {{ dist_dir }}/uploads
      - {{ dist_dir }}/conf
      - {{ dist_dir }}/db
      - {{ dist_dir }}/log
    - user: {{ username }}
    - group: {{ username }}
    - mode: 750
    - require:
      - file: {{ dist_dir }}
      - archive: mmonit-unpack
    - require_in:
      - service: mmonit

{{ dist_dir }}/{{ dist_name }}/docroot/uploads:
  file.symlink:
    - target: ../../uploads
    - force: True
    - require:
      - archive: mmonit-unpack
    - require_in:
      - service: mmonit

{{ dist_dir }}/conf/server.xml:
  file.managed:
    - source: salt://monit/server.xml.jinja
    - template: jinja
    - makedirs: True
    - user: root
    - group: {{ username }}
    - mode: 640
    - context:
      service_port: {{ service_port }}
      nginx_server_name: {{ nginx_server_name }}
      dist_dir: {{ dist_dir }}
      username: {{ username }}
      db_type: {{ db_type }}
      db_path: {{ db_path }}
      db_name: {{ db_name }}
      db_user: {{ db_user }}
      db_password: {{ db_password }}
      license_owner: {{ license_owner }}
      license_data: |
        {{ license_data | indent(8) }}
    - require:
      - file: {{ dist_dir }}/conf
    - watch_in:
      - service: mmonit

/etc/nginx/sites-available/{{ nginx_conf_name }}.conf:
  file.managed:
    - source: salt://monit/nginx-site.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      service_port: {{ service_port }}
      nginx_server_name: {{ nginx_server_name }}
      nginx_conf_name: {{ nginx_conf_name }}
      dist_dir: {{ dist_dir }}
      ssl_key: {{ nginx_key }}
      ssl_cert: {{ nginx_cert }}
    - require:
      - pkg: nginx-full
    - watch_in:
      - service: nginx

/etc/nginx/sites-enabled/{{ nginx_conf_name }}.conf:
  file.symlink:
    - target: ../sites-available/{{ nginx_conf_name }}.conf
    - watch_in:
      - service: nginx

/etc/init/mmonit.conf:
  file.managed:
    - source: salt://monit/upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      username: {{ username }}
      dist_dir: {{ dist_dir }}
    - watch_in:
      - service: mmonit
