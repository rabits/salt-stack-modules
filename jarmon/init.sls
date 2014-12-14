#
# Jarmon RRD web analyzer
#

include:
  - nginx

{% set nginx_listen = salt['pillar.get']('net:hosts:%s:ip'|format(grains['id']), '127.0.0.1') %}
{% set nginx_server_name = 'stat.' + salt['pillar.get']('net:main_domain', 'localhost') %}
{% set nginx_conf_name = salt['additional.inverse'](nginx_server_name) %}

{% set home_dir = salt['pillar.get']('monitoring:stat_dir', '/srv/www/' + nginx_conf_name) %}

{{ home_dir }}:
  file.recurse:
    - source: salt://jarmon/jarmon-11.8
    - user: root
    - group: www-data
    - clean: True
    - dir_mode: 750
    - file_mode: 640

/etc/nginx/sites-available/{{ nginx_conf_name }}.conf:
  file.managed:
    - source: salt://jarmon/nginx-site.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      nginx_listen: {{ nginx_listen }}
      nginx_server_name: {{ nginx_server_name }}
      nginx_conf_name: {{ nginx_conf_name }}
      home_dir: {{ home_dir }}
    - require:
      - pkg: nginx-full
    - watch_in:
      - service: nginx

/etc/nginx/sites-enabled/{{ nginx_conf_name }}.conf:
  file.symlink:
    - target: ../sites-available/{{ nginx_conf_name }}.conf
    - watch_in:
      - service: nginx
