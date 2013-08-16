#
# Xonotic - good 3d shooter
#

getdeb-games-repo:
  pkgrepo.managed:
   - name: deb http://archive.getdeb.net/ubuntu {{ grains['oscodename'] }}-getdeb games
   - key_url: http://archive.getdeb.net/getdeb-archive.key
   - require:
     - cmd: arch
   - require_in:
     - pkg: xonotic

xonotic:
  pkg.installed
