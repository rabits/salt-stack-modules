#
# XBMC home media center
#

include:
  - sensors
  - fglrx

# Radeon repo
xbmc-xvba-repo:
  pkgrepo.managed:
   - ppa: wsnipex/xbmc-xvba
   - required_in:
     - pkg: xbmc

xbmc:
  pkg:
    - installed
  group:
    - present
  user.present:
    - gid: {{ salt['file.group_to_gid']('xbmc') }}
    - groups:
      - video
      - audio
    - require:
      - group: xbmc
      - pkg: xbmc

/home/xbmc/.xbmc/userdata/advancedsettings.xml:
  file.managed:
    - source: salt://xbmc/advancedsettings.xml
    - user: xbmc
    - group: xbmc
    - mode: 644
    - makedirs: True
    - require:
      - pkg: xbmc
      - user: xbmc
