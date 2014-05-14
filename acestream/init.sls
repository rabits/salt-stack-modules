#
# AceStream - torrent streams engine
#

acestream-repo:
  pkgrepo.managed:
   - name: deb http://repo.steampowered.com/steam precise steam
   - key_url: http://repo.acestream.org/keys/acestream.public.key
   - require_in:
     - pkg: steam

acestream-engine:
  pkg.installed:
    - require:
      - pkgrepo: acestream-repo
