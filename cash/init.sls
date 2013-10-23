#
# DNC-Kassa frontend
#

include:
  - cash.dnc-kassa

kassir:
  group:
    - present
  user.present:
    - gid: {{ salt['file.group_to_gid']('kassir') }}
    - groups:
      - dnc
      - dialout
    - require:
      - group: kassir
      - group: dnc

xinit:
  pkg.installed

matchbox-window-manager:
  pkg.installed

cash:
  file.managed:
    - name: /usr/local/bin/cash-startup.sh
    - source: salt://cash/cash-startup.sh
    - user: root
    - group: kassir
    - mode: 750
    - require:
      - file: dnc
      - pkg: matchbox-window-manager
  service.running:
    - require:
      - pkg: xinit
      - user: kassir
    - watch:
      - file: dnc
      - file: cash

/etc/init/cash.conf:
  file.managed:
    - source: salt://cash/upstart.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: xinit
      - user: kassir
      - file: cash
    - watch_in:
      - service: cash

/etc/X11/Xwrapper.config:
  file.managed:
    - source: salt://cash/xwrapper.conf
    - user: root
    - group: root
    - mode: 644
    - require_in:
      - service: cash
    - require:
      - file: dnc
