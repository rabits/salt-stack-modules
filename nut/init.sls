#
# NUT UPS monitoring
#

include:
  - udev

nut:
  pkg.installed

/etc/udev/rules.d/10-nut-ups.rules:
  file.managed:
    - source: salt://nut/udev.rules
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nut
    - watch_in:
      - cmd: udev_trigger

{% for conf in ['nut.conf', 'ups.conf', 'upsd.conf', 'upsmon.conf', 'upsd.users'] %}
/etc/nut/{{ conf }}:
  file.managed:
    - source: salt://nut/{{ conf }}
    - user: root
    - group: nut
    - mode: 640
    - require:
      - pkg: nut
    - watch_in:
      - service: nut-server
      - service: nut-client
{% endfor %}

nut-server:
  service.running

nut-client:
  service.running
