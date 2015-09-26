#
# KODI home media center
#

{% from 'monit/macros.sls' import monit with context %}

include:
  - sensors
  - acestream

kodi-repo:
  pkgrepo.managed:
   - ppa: team-xbmc/ppa
   - required_in:
     - pkg: kodi

kodi:
  pkg.installed:
    - pkgs:
      - kodi
      - kodi-pvr-iptvsimple
  group:
    - present
    - require:
      - pkg: kodi
  user.present:
    - gid_from_name: True
    - groups:
      - video
      - audio
      - plugdev
      - users
      - dialout
      - dip
    - require:
      - group: kodi
      - pkg: kodi
  service.running:
    - require:
      - pkg: xinit
      - user: kodi
      - file: /etc/security/limits.d/kodi.conf
      - file: /srv/bin/kodi
    - watch:
      - pkg: kodi
      - file: /etc/init/kodi.conf

{{ monit('kodi') }}

linux-sound-base:
  pkg.installed:
    - require:
      - pkg: kodi

alsa-utils:
  pkg.installed:
    - require:
      - pkg: kodi

xinit:
  pkg.installed:
    - require:
      - pkg: kodi

kodi-additional-pkgs:
  pkg.installed:
    - pkgs:
      - udisks
      - upower
      - alsa-utils
      - mesa-utils
      - libmad0
      - libmpeg2-4
      - avahi-daemon
      - libnfs1
      - consolekit
      - pm-utils
      - vdpauinfo
      - mesa-vdpau-drivers
    - require:
      - pkg: kodi

/etc/security/limits.d/kodi.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: kodi - nice -1
    - require:
      - user: kodi

/srv/bin/kodi:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - contents: |
        #!/bin/sh
        # WARNING:
        # This file is under CM control - all manual changes will be removed
        #
        # Can help with init non-connected display on HDMI-0
        # GRUB_CMDLINE_LINUX_DEFAULT="quiet splash drm_kms_helper.edid_firmware=edid/1920x1080.bin video=HDMI-A-1:1920x1080R-24@60D"
        
        # Enable audio when hdmi connection forced
        xrandr --output HDMI-0 --set audio on
        /usr/bin/kodi --standalone
    - require:
      - user: kodi
      - file: /srv/bin

/home/kodi/.kodi/userdata/advancedsettings.xml:
  file.managed:
    - source: salt://kodi/advancedsettings.xml
    - user: kodi
    - group: kodi
    - mode: 644
    - makedirs: True
    - require:
      - pkg: kodi
      - user: kodi

/etc/init/kodi.conf:
  file.managed:
    - source: salt://kodi/upstart.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: xinit
      - pkg: kodi
      - user: kodi

/etc/X11/Xwrapper.config:
  file.managed:
    - source: salt://kodi/xwrapper.conf
    - user: root
    - group: root
    - mode: 644
    - require_in:
      - service: kodi
    - require:
      - pkg: kodi

/srv/media:
  file.directory:
    - user: kodi
    - group: kodi
    - mode: 755
    - makedirs: True

/srv/media/photos:
  file.directory:
    - user: kodi
    - group: kodi
    - mode: 777
    - makedirs: True

/srv/media/video:
  file.directory:
    - user: kodi
    - group: kodi
    - mode: 777
    - makedirs: True

/srv/media/video/movies:
  file.directory:
    - user: kodi
    - group: kodi
    - mode: 777
    - makedirs: True

/srv/media/video/serials:
  file.directory:
    - user: kodi
    - group: kodi
    - mode: 777
    - makedirs: True

/srv/media/video/clips:
  file.directory:
    - user: kodi
    - group: kodi
    - mode: 777
    - makedirs: True

/srv/media/music:
  file.directory:
    - user: kodi
    - group: kodi
    - mode: 777
    - makedirs: True
