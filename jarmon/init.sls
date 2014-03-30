#
# Jarmon RRD web analyzer
#

include:
  - nginx

{{ salt['pillar.get']('monitoring:stat_dir', '/srv/www/stat') }}:
  file.recurse:
    - source: salt://jarmon/jarmon-11.8
    - user: root
    - group: www-data
    - clean: True
    - dir_mode: 750
    - file_mode: 640

/etc/nginx/sites-available/{{ salt['pillar.get']('monitoring:conf_filename', 'stat') }}.conf:
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

/etc/nginx/sites-enabled/{{ salt['pillar.get']('monitoring:conf_filename', 'stat') }}.conf:
  file.symlink:
    - target: ../sites-available/{{ salt['pillar.get']('monitoring:conf_filename', 'stat') }}.conf
    - watch_in:
      - service: nginx
