#
# DNC Admin soft
#

include:
  - cash.dnc-kassa

{% for name in ['SetupLoadUnload', 'AccessRights'] %}
/usr/bin/{{ name }}:
  file.managed:
    - source: salt://cash/dnc-kassa/dist/usr/bin_{{ grains['cpuarch'] }}/{{ name }}
    - user: root
    - group: dnc
    - mode: 750
    - require:
      - group: dnc
    - require_in:
      - file: dnc
{% endfor %}
