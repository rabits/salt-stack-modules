#
# TMux - advanced terminal multiplexer
#

tmux:
  pkg.installed

/etc/tmux.conf:
  file.managed:
    - source: salt://tmux/tmux.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: tmux

/etc/tmux:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /etc/tmux.conf

/etc/tmux/disk.sh:
  file.managed:
    - source: salt://tmux/disk.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /etc/tmux

/etc/tmux/mem.sh:
  file.managed:
    - source: salt://tmux/mem.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /etc/tmux

/etc/tmux/net.sh:
  file.managed:
    - source: salt://tmux/net.sh.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /etc/tmux
