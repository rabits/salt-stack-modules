#
# RXVT Terminal emulator + terminus font
#

rxvt-unicode-256color:
  pkg.installed

xfonts-terminus:
  pkg.installed

x-terminal-emulator:
  alternatives.install:
    - link: /usr/bin/x-terminal-emulator
    - path: /usr/bin/urxvt
    - priority: 100
    - require:
      - pkg: rxvt-unicode-256color
