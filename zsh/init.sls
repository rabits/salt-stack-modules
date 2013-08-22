#
# ZSH shell
#

zsh:
  pkg.installed

/etc/zsh/zshrc:
  file.managed:
    - source: salt://zsh/zshrc
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: zsh
