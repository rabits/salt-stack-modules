#
# Awesome - window manager
#

awesome:
  pkg.installed

light-locker:
  pkg.installed

/etc/xdg/awesome/rc.lua:
  file.managed:
    - source: salt://awesome/rc.lua
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: awesome

/usr/share/awesome/lib/scratch:
  file.recurse:
    - source: salt://awesome/lib/scratch
    - user: root
    - group: root
    - clean: True
    - dir_mode: 755
    - file_mode: 644

/usr/share/awesome/themes/green_rabit:
  file.recurse:
    - source: salt://awesome/themes/green_rabit
    - user: root
    - group: root
    - clean: True
    - dir_mode: 755
    - file_mode: 644
