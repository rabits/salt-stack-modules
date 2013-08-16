#
# LibVirt VM control
#

include:
  - users

libvirt-pkgs:
  pkg.installed:
    - pkgs:
      - libvirt-bin
      - virt-manager
      - virtinst
      - virt-viewer

{% for user in pillar['users'] %}
{% if 'admin' in pillar['users'][user] and pillar['users'][user]['admin'] == True %}
extend:
  {{ user }}:
    user.present:
     - optional_groups:
       - libvirtd
{% endif %}
{% endfor %}
