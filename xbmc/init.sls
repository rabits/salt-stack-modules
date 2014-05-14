#
# XBMC home media center
#

include:
  - sensors
  - fglrx
  - acestream

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
    - gid_from_name: True
    - groups:
      - video
      - audio
    - require:
      - group: xbmc
      - pkg: xbmc
  service.running:
    - require:
      - pkg: xinit
      - user: xbmc
    - watch:
      - pkg: xbmc

linux-sound-base:
  pkg.installed:
    - require:
      - pkg: xbmc

alsa-utils:
  pkg.installed:
    - require:
      - pkg: xbmc

xinit:
  pkg.installed:
    - require:
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

/etc/init/xbmc.conf:
  file.managed:
    - source: salt://xbmc/upstart.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: xinit
      - pkg: xbmc
      - user: xbmc
    - watch_in:
      - file: /etc/asound.conf
      - service: xbmc

/etc/X11/Xwrapper.config:
  file.managed:
    - source: salt://xbmc/xwrapper.conf
    - user: root
    - group: root
    - mode: 644
    - require_in:
      - service: xbmc
    - require:
      - pkg: xbmc

/etc/X11/xorg.conf:
  file.managed:
    - source: salt://xbmc/xorg.conf
    - user: root
    - group: root
    - mode: 644
    - require_in:
      - service: xbmc
    - require:
      - pkg: xbmc

/etc/asound.conf:
  file.managed:
    - source: salt://xbmc/asound.conf
    - user: root
    - group: root
    - mode: 644

/srv/media:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/srv/media/photos:
  file.directory:
    - user: root
    - group: xbmc
    - mode: 775
    - makedirs: True

/srv/media/video:
  file.directory:
    - user: root
    - group: xbmc
    - mode: 755
    - makedirs: True

/srv/media/video/movies:
  file.directory:
    - user: root
    - group: xbmc
    - mode: 777
    - makedirs: True

/srv/media/video/serials:
  file.directory:
    - user: root
    - group: xbmc
    - mode: 777
    - makedirs: True

/srv/media/video/clips:
  file.directory:
    - user: root
    - group: xbmc
    - mode: 777
    - makedirs: True

/srv/media/music:
  file.directory:
    - user: root
    - group: xbmc
    - mode: 777
    - makedirs: True
