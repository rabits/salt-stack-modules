#
# SMPlayer best frontend for mplayer
#

vaapi-repo:
  pkgrepo.managed:
   - ppa: sander-vangrieken/vaapi
   - require:
     - cmd: arch
   - require_in:
     - pkg: intel-video-vaapi

intel-video-vaapi:
  pkg.installed:
    - pkgs:
      - mplayer-vaapi
      - libva-intel-vaapi-driver

smplayer:
  pkg.installed
