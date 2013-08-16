#
# SMART Disk monitoring
#

{% if salt['additional.sd_list']() %}
smartmontools:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: smartmontools
    - watch:
      - file: /etc/default/smartmontools
      - file: /etc/smartd.conf

{% for device in salt['additional.sd_list']() %}
smartctl -s on /dev/{{ device }}:
  cmd.run:
    - onlyif: "smartctl -i /dev/{{ device }} | grep -q 'SMART support is: Disabled'"
    - require:
      - pkg: smartmontools
{% endfor %}

/etc/default/smartmontools:
  file.managed:
    - source: salt://smart/default
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: smartmontools

/etc/smartd.conf:
  file.managed:
    - source: salt://smart/smartd.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: smartmontools
{% endif %}
