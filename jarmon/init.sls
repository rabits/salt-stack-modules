#
# Jarmon RRD web analyzer
#

include:
  - nginx

{{ pillar['monitoring']['stat_dir'] }}:
  file.recurse:
    - source: salt://jarmon/jarmon-11.8
    - user: root
    - group: www-data
    - clean: True
    - dir_mode: 750
    - file_mode: 640

/etc/nginx/sites-available/stat.{{ pillar['net']['main_domain'] }}.conf:
  file.managed:
    - source: salt://jarmon/stat.nginx.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx-full
    - watch_in:
      - service: nginx

/etc/nginx/sites-enabled/stat.{{ pillar['net']['main_domain'] }}.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/stat.{{ pillar['net']['main_domain'] }}.conf
    - watch_in:
      - service: nginx
