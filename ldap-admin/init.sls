#
# LDAP administration place
#

include:
  - php
  - nginx

{% import 'openssl/vars.sls' as ssl with context %}

{% set nginx_listen = salt['pillar.get']('net:hosts:%s:ip'|format(grains['id']), '127.0.0.1') %}
{% set nginx_server_name = 'ldap.' + salt['pillar.get']('net:main_domain', 'localhost') %}
{% set nginx_conf_name = salt['additional.inverse'](nginx_server_name) %}
{% set nginx_key = salt['pillar.get']('ldap:ssl_key', ssl.key) %}
{% set nginx_cert = salt['pillar.get']('ldap:ssl_cert', ssl.cert) %}

{% set home_dir = salt['pillar.get']('ldap:admin_dir', '/srv/www/' + nginx_conf_name) %}

ldapadmin-packages:
  pkg.installed:
    - pkgs:
      - php5-ldap
    - watch_in:
      - service: php5

{{ home_dir }}:
  file.recurse:
    - source: salt://ldap-admin/src
    - user: root
    - group: www-data
    - clean: True
    - dir_mode: 755
    - file_mode: 644
    - exclude_pat: .*

{{ home_dir }}/.config.php:
  file.managed:
    - source: salt://ldap-admin/config.php.jinja
    - template: jinja
    - user: root
    - group: www-data
    - mode: 640
    - require:
      - file: {{ home_dir }}

/etc/nginx/sites-available/{{ nginx_conf_name }}.conf:
  file.managed:
    - source: salt://ldap-admin/nginx-site.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      nginx_listen: {{ nginx_listen }}
      nginx_server_name: {{ nginx_server_name }}
      nginx_conf_name: {{ nginx_conf_name }}
      home_dir: {{ home_dir }}
      ssl_ca_crt: {{ ssl.ca_crt }}
      ssl_crl: {{ ssl.crl }}
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
