#
# Steam client
#

include:
  - x86

steam-repo:
  pkgrepo.managed:
   - name: deb http://repo.steampowered.com/steam precise steam
   - keyid: B05498B7
   - keyserver: keyserver.ubuntu.com
   - require:
     - cmd: arch
   - require_in:
     - pkg: steam

steam:
  pkg.installed

steam-launcher:
  pkg.installed
