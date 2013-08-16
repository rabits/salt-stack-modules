#
# x386 libraries
#

arch:
  cmd.wait:
    - name: dpkg --add-architecture i386
    - watch:
      - pkg: ia32-libs

ia32-libs:
  pkg.installed
