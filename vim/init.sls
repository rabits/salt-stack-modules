#
# VIM - console editor
#

vim:
  pkg.installed

/etc/vim/vimrc:
  file.managed:
    - source: salt://vim/vimrc
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: vim
