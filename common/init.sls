#
# Common states
#

/srv/bin:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
