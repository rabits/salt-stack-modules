#
# Seafile - Shared versioning file server like dropbox
#
# Hint:
#  - You can mount huge dist into /srv/seafile/data directory before install seafile

include:
  - nginx

{% import 'openssl/vars.sls' as ssl with context %}

{% set nginx_server_name = 'fs.' + salt['pillar.get']('net:main_domain', 'localhost') %}
{% set nginx_conf_name = salt['additional.inverse'](nginx_server_name) %}
{% set nginx_key = salt['pillar.get']('seafile:ssl_key', ssl.key) %}
{% set nginx_cert = salt['pillar.get']('seafile:ssl_cert', ssl.cert) %}

{% set home_dir = salt['pillar.get']('seafile:home_dir', '/srv/seafile') %}
{% set dist_def = 'https://bitbucket.org/haiwen/seafile/downloads/seafile-server_4.0.6_x86-64.tar.gz' %}
{% set dist = salt['pillar.get']('seafile:dist', dist_def) %}
{% set username = salt['pillar.get']('seafile:username', 'seafile') %}

{% set db_type = salt['pillar.get']('seafile:db_type', 'sqlite3') %}
{% set db_path = salt['pillar.get']('seafile:db_path', '') %}
{% set db_seafile_name = salt['pillar.get']('seafile:db_seafile_name', 'seafile_db') %}
{% set db_seahub_name = salt['pillar.get']('seafile:db_seahub_name', 'seafile_seahub_db') %}
{% set db_ccnet_name = salt['pillar.get']('seafile:db_ccnet_name', 'seafile_ccnet_db') %}
{% set db_user = salt['pillar.get']('seafile:db_user', '') %}
{% set db_password = salt['pillar.get']('seafile:db_password', '') %}

{% set ldap_url = salt['pillar.get']('seafile:ldap_url', '') %}
{% set ldap_userbase = salt['pillar.get']('seafile:ldap_userbase', 'ou=Users,dc=example,dc=net') %}
{% set ldap_attr = salt['pillar.get']('seafile:ldap_attr', 'cn') %}
{% set ldap_filter = salt['pillar.get']('seafile:ldap_filter', '') %}

{% set secret_key = salt['pillar.get']('seafile:secret_key', salt['random.str_encode'](salt['grains.get_or_set_hash']('gogs:instance', 32), 'base64')) %}

seafile-packages:
  pkg.installed:
    - pkgs:
      - python-setuptools
      - python-simplejson
      - python-imaging
      - python-psycopg2
  file.managed:
    - name: {{ home_dir }}/{{ dist.split('/')[-1] }}
    - source:
      - '{{ dist }}'
      - '{{ dist_def }}'
    - replace: False
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: seafile-packages

{{ username }}:
  group:
    - present
  user.present:
    - gid_from_name: True
    - shell: /bin/false
    - system: True
    - createhome: False
    - require:
      - group: {{ username }}
  service.running:
    - name: seafile
    - require:
      - pkg: seafile-packages
      - user: {{ username }}

/etc/init/{{ username }}.conf:
  file.managed:
    - source: salt://seafile/upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      home_dir: {{ home_dir }}
    - require:
      - pkg: seafile-packages
    - watch_in:
      - service: seafile

/etc/logrotate.d/seafile.conf:
  file.managed:
    - source: salt://seafile/logrotate.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      home_dir: {{ home_dir }}
    - require:
      - pkg: seafile-packages

{{ home_dir }}:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 755
    - makedirs: True
    - require:
      - user: {{ username }}
      - pkg: seafile-packages

{{ home_dir }}/seahub_settings.py:
  file.managed:
    - source: salt://seafile/seahub_settings.py.jinja
    - template: jinja
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - context:
      domain: {{ nginx_server_name }}
      db_type: {{ db_type }}
      db_path: {{ db_path }}
      db_name: {{ db_seahub_name }}
      db_user: {{ db_user }}
      db_password: {{ db_password }}
      secret_key: {{ secret_key }}
    - watch_in:
      - service: seafile
    - require:
      - user: {{ username }}
      - file: {{ home_dir }}

{{ home_dir }}/ccnet:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 700
    - makedirs: True
    - require:
      - user: {{ username }}
      - file: {{ home_dir }}

{{ home_dir }}/ccnet/ccnet.conf:
  file.managed:
    - source: salt://seafile/ccnet_ccnet.conf.jinja
    - template: jinja
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - context:
      domain: {{ nginx_server_name }}
      db_type: {{ db_type }}
      db_path: {{ db_path }}
      db_name: {{ db_ccnet_name }}
      db_user: {{ db_user }}
      db_password: {{ db_password }}
      ldap_url: {{ ldap_url }}
      ldap_userbase: {{ ldap_userbase }}
      ldap_attr: {{ ldap_attr }}
      ldap_filter: {{ ldap_filter }}
    - watch_in:
      - service: seafile
    - require:
      - user: {{ username }}
      - file: {{ home_dir }}/ccnet

{{ home_dir }}/conf:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 755
    - makedirs: True
    - require:
      - user: {{ username }}
      - file: {{ home_dir }}

{{ home_dir }}/conf/seafdav.conf:
  file.managed:
    - source: salt://seafile/conf_seafdav.conf
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - watch_in:
      - service: seafile
    - require:
      - user: {{ username }}
      - file: {{ home_dir }}/conf

{{ home_dir }}/data:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 755
    - makedirs: True
    - require:
      - user: {{ username }}
      - file: {{ home_dir }}

{{ home_dir }}/data/seafile.conf:
  file.managed:
    - source: salt://seafile/seafile.conf.jinja
    - template: jinja
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - context:
      domain: {{ nginx_server_name }}
      db_type: {{ db_type }}
      db_path: {{ db_path }}
      db_name: {{ db_seafile_name }}
      db_user: {{ db_user }}
      db_password: {{ db_password }}
    - watch_in:
      - service: seafile
    - require:
      - user: {{ username }}
      - file: {{ home_dir }}/data

/etc/nginx/sites-available/{{ nginx_conf_name }}.conf:
  file.managed:
    - source: salt://seafile/nginx-site.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      nginx_server_name: {{ nginx_server_name }}
      nginx_conf_name: {{ nginx_conf_name }}
      home_dir: {{ home_dir }}
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
