#
# Nginx webserver
#

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

nginx:
  service.running:
    - reload: True
    - watch:
      - pkg: nginx-full
