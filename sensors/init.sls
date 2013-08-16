#
# Sensors temperature etc
#

lm-sensors:
  pkg.installed

libsensors4:
  pkg.installed

yes "yes" | sensors-detect:
  cmd.wait:
    - watch:
      - pkg: lm-sensors
