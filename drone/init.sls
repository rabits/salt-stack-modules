#
# Drone - continuous integration server based on docker
#

{% set dist = salt['pillar.get']('drone:dist', 'http://downloads.drone.io/master/drone.deb') %}

docker.io:
  pkg.installed

drone-package:
  pkg.installed:
    - sources:
      - drone: {{ dist }}
    - require:
      - pkg: docker.io

drone:
  service.running:
    - watch:
      - pkg: drone-package
