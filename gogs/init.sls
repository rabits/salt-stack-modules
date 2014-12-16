#
# GoGs - github-like private git server
#

include:
  - nginx
  - git

{% import 'openssl/vars.sls' as ssl with context %}

{% set nginx_server_name = 'git.' + salt['pillar.get']('net:main_domain', 'localhost') %}
{% set nginx_conf_name = salt['additional.inverse'](nginx_server_name) %}
{% set nginx_key = salt['pillar.get']('gogs:ssl_key', ssl.key) %}
{% set nginx_cert = salt['pillar.get']('gogs:ssl_cert', ssl.cert) %}

{% set home_dir = salt['pillar.get']('gogs:home_dir', '/srv/git') %}
{% set dist_def = 'http://gogs.dn.qbox.me/gogs_v0.5.8_linux_amd64.zip' %}
{% set dist = salt['pillar.get']('gogs:dist', dist_def) %}
{% set dist_dir = salt['pillar.get']('gogs:dist_dir', '/srv/gogs') %}
{% set username = salt['pillar.get']('gogs:username', 'git') %}

{% set db_type = salt['pillar.get']('gogs:db_type', 'sqlite3') %}
{% set db_path = salt['pillar.get']('gogs:db_path', 'data/gogs.db') %}
{% set db_name = salt['pillar.get']('gogs:db_name', '') %}
{% set db_user = salt['pillar.get']('gogs:db_user', '') %}
{% set db_password = salt['pillar.get']('gogs:db_password', '') %}


{{ username }}:
  group.present:
    - system: True
  user.present:
    - gid_from_name: True
    - shell: /bin/sh
    - system: True
    - createhome: False
    - home: {{ home_dir }}
    - require:
      - group: {{ username }}

{{ home_dir }}:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 750
    - require:
      - user: {{ username }}

{{ dist_dir }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755

gogs-unpack:
  archive.extracted:
    - name: {{ dist_dir }}
    - archive_user: root
    - archive_format: tar
    - source:
      - '{{ dist }}'
      - '{{ dist_def }}'
    - if_missing: {{ dist_dir }}
    - keep: True
    - require:
      - user: {{ username }}

gogs-subdirs:
  file.directory:
    - names:
      - {{ dist_dir }}/data
      - {{ dist_dir }}/gogs/custom
      - {{ dist_dir }}/log
    - user: {{ username }}
    - group: {{ username }}
    - mode: 750
    - require:
      - file: {{ dist_dir }}
      - archive: gogs-unpack
    - require_in:
      - service: gogs

{{ dist_dir }}/gogs/custom/conf/app.ini:
  file.managed:
    - source: salt://gogs/app.ini.jinja
    - template: jinja
    - makedirs: True
    - user: git
    - group: git
    - mode: 640
    - context:
      domain: {{ nginx_server_name }}
      home_dir: {{ home_dir }}
      dist_dir: {{ dist_dir }}
      username: {{ username }}
      db_type: {{ db_type }}
      db_path: {{ db_path }}
      db_name: {{ db_name }}
      db_user: {{ db_user }}
      db_password: {{ db_password }}
    - watch_in:
      - service: gogs

/etc/nginx/sites-available/{{ nginx_conf_name }}.conf:
  file.managed:
    - source: salt://gogs/nginx-site.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      nginx_server_name: {{ nginx_server_name }}
      nginx_conf_name: {{ nginx_conf_name }}
      home_dir: {{ home_dir }}
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

/etc/init/gogs.conf:
  file.managed:
    - source: salt://gogs/upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      username: {{ username }}
      home_dir: {{ home_dir }}
      dist_dir: {{ dist_dir }}
    - watch_in:
      - service: gogs

gogs:
  service.running:
    - require:
      - user: {{ username }}
    - watch:
      - file: {{ dist_dir }}/gogs/custom/conf/app.ini
      - archive: gogs-unpack
