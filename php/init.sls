#
# PHP FPM server
#

{% if salt['additional.state_in'](['postgresql']) %}
include:
  - php.postgresql
{% endif %}

php5:
  pkg.installed:
    - pkgs:
      - php5-fpm
      - php5-common
  service.running:
    - name: php5-fpm
    - watch:
      - pkg: php5

/etc/php5/fpm/php-fpm.conf:
  file.managed:
    - source: salt://php/php-fpm.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: php5
    - watch_in:
      - service: php5

/etc/php5/fpm/pool.d/www.conf:
  file.managed:
    - source: salt://php/www.pool.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: php5
    - watch_in:
      - service: php5

/etc/php5/fpm/php.ini:
  file.managed:
    - source: salt://php/php.ini
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: php5
    - watch_in:
      - service: php5
