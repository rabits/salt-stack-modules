#
# Video accelerating libraries
#

videoaccel:
  pkg.installed:
    - names:
      - vainfo
      - libva-glx1
{% if salt['additional.substring_search']('Radeon', grains['gpus']) %}
      # Radeon XvBA
      - xvba-va-driver
{% elif salt['additional.substring_search']('intel', grains['gpus']) %}
      # Intel vaapi
      - libva-intel-vaapi-driver
{% elif salt['additional.substring_search']('GeForce', grains['gpus']) %}
      # Nvidia vdpau
      - vdpau-va-driver
{% endif %}
