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

{% for user in salt['pillar.get']('users', {}) %}
{% if salt['pillar.get']('users:%s:admin'|format(user), False) == True %}
extend:
  {{ user }}:
    user.present:
     - optional_groups:
       - libvirtd
{% endif %}
{% endfor %}
