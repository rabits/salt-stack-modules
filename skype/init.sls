#
# Skype - ip videocall
#

include:
  - x86

canonical-partner-repo:
  pkgrepo.managed:
   - name: deb http://archive.canonical.com/ubuntu {{ grains['oscodename'] }} partner
   - require:
     - cmd: arch
   - require_in:
     - pkg: skype

skype:
  pkg.installed
