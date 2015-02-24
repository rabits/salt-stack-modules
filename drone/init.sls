#
# Drone - continuous integration server based on docker
#

{% set dist_def = 'http://downloads.drone.io/master/drone.deb' %}
{% set dist = salt['pillar.get']('drone:dist', dist_def) %}

docker.io:
  pkg.installed

drone-package:
  pkg.installed:
    - sources:
      - drone:
        - '{{ dist }}'
        - '{{ dist_def }}'
    - require:
      - pkg: docker.io

drone:
  service.running:
    - watch:
      - pkg: drone-package
