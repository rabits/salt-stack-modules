#
# Nginx webserver
#

{% import 'openssl/vars.sls' as ssl with context %}
{% from 'monit/macros.sls' import monit with context %}

nginx-full:
  pkg.installed

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://nginx/nginx.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx-full
    - watch_in:
      - service: nginx

/etc/nginx/common.conf:
  file.managed:
    - source: salt://nginx/common.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx-full
    - watch_in:
      - service: nginx

/etc/nginx/ssl.conf:
  file.managed:
    - source: salt://nginx/ssl.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      ssl_ca_crt: {{ ssl.ca_crt }}
    - require:
      - pkg: nginx-full
    - watch_in:
      - service: nginx

/etc/nginx/sites-available/www-util.conf:
  file.managed:
    - source: salt://nginx/www-util.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx-full
    - watch_in:
      - service: nginx

/etc/nginx/sites-enabled/www-util.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/www-util.conf
    - watch_in:
      - service: nginx

/etc/nginx/sites-enabled/default:
  file.absent:
    - require_in:
      - service: nginx

nginx:
  service.running:
    - reload: True
    - watch:
      - pkg: nginx-full

{{ monit('nginx') }}
