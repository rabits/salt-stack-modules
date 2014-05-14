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

steam:
  pkg.installed:
    - require:
      - pkgrepo: steam-repo

steam-launcher:
  pkg.installed:
    - require:
      - pkgrepo: steam-repo
