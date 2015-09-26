#
# Monit module macro
#

{% macro monit(module, suffix, subname) -%}
/etc/monit/conf.d/{{ module }}{{ subname|default('') }}{{ suffix|default('') }}.conf:
  file.managed:
    - source: salt://{{ module }}/monit{{ suffix|default('') }}.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - context:
      subname: {{ subname|default('') }}
    - require:
      - pkg: monit
    - watch_in:
      - service: monit
{%- endmacro %}
