#
# DNC-Kassa basic installer
#

libqt3-mt:
  pkg.installed

libpq5:
  pkg.installed

/etc/dancy:
  file.directory:
    - user: root
    - group: dnc
    - mode: 750

/etc/hwsrv:
  file.recurse:
    - source: salt://cash/dnc-kassa/dist/etc/hwsrv
    - user: root
    - group: dnc
    - dir_mode: 770
    - file_mode: 660
    - require_in:
      - file: dnc

/etc/hwsrv/hw.conf:
  file.managed:
    - source: salt://cash/dnc-kassa/hw.conf
    - user: root
    - group: dnc
    - mode: 664
    - replace: False
    - require:
      - file: /etc/hwsrv
    - require_in:
      - file: dnc

/etc/hwsrv/withoutFR.tab:
  file.managed:
    - source: salt://cash/dnc-kassa/withoutFR.tab
    - user: root
    - group: dnc
    - mode: 664
    - replace: False
    - require:
      - file: /etc/hwsrv
    - require_in:
      - file: dnc

/etc/qt3/qtrc:
  file.managed:
    - source: salt://cash/dnc-kassa/dist/etc/qtrc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - require:
      - file: /etc/dancy
    - require_in:
      - file: dnc

/etc/dancy/LinCash_db.conf:
  file.managed:
    - source: salt://cash/dnc-kassa/db.conf.jinja
    - template: jinja
    - context:
      dbname: LinCash
    - user: root
    - group: dnc
    - mode: 640
    - require:
      - group: dnc
      - file: /etc/dancy
    - require_in:
      - file: dnc

/etc/dancy/Trans_db.conf:
  file.managed:
    - source: salt://cash/dnc-kassa/db.conf.jinja
    - template: jinja
    - context:
      dbname: Transaction
    - user: root
    - group: dnc
    - mode: 640
    - require:
      - group: dnc
      - file: /etc/dancy
    - require_in:
      - file: dnc

dnc:
  group:
    - present
  file.managed:
    - name: /usr/local/bin/dnc-run.sh
    - source: salt://cash/dnc-kassa/dnc-run.sh
    - user: root
    - group: dnc
    - mode: 750
    - require:
      - group: dnc

/usr/share/dnc:
  file.recurse:
    - source: salt://cash/dnc-kassa/dist/usr/share/dnc
    - user: root
    - group: root
    - require_in:
      - file: dnc

{% for name in ['reshka', 'confGUI', 'Display', 'RMK', 'WareProject'] %}
/usr/bin/{{ name }}:
  file.managed:
    - source: salt://cash/dnc-kassa/dist/usr/bin_{{ grains['cpuarch'] }}/{{ name }}
    - user: root
    - group: dnc
    - mode: 750
    - require:
      - group: dnc
    - require_in:
      - file: dnc
{% endfor %}

/usr/local/lib/dnc:
  file.recurse:
    - source: salt://cash/dnc-kassa/dist/lib_{{ grains['cpuarch'] }}
    - user: root
    - group: root
    - require_in:
      - file: dnc
