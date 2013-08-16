#
# Collectd monitor client
#

{% if salt['additional.state_in'](['nginx']) %}
include:
  - collectd.nginx
{% endif %}
{% if salt['additional.state_in'](['openvpn.server']) %}
include:
  - collectd.openvpn
{% endif %}
{% if salt['additional.state_in'](['nut']) %}
include:
  - collectd.nut
{% endif %}
{% if salt['additional.state_in'](['libvirt']) %}
include:
  - collectd.libvirt
{% endif %}
{% if salt['additional.state_in'](['postgresql']) %}
include:
  - collectd.postgresql
{% endif %}

include:
  - sensors

collectd5-repo:
  pkgrepo.managed:
   - name: deb http://ppa.launchpad.net/vbulax/collectd5/ubuntu precise main 
   - keyid: 013B9839
   - keyserver: keyserver.ubuntu.com
   - require_in:
     - pkg: collectd-core

collectd-core:
  pkg.installed

/etc/collectd/collectd.d:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/collectd/collectd.conf:
  file.managed:
    - source: salt://collectd/collectd.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: collectd
    - require:
      - pkg: collectd-core
      - file: /etc/collectd/collectd.d

collectd:
  service.running:
    - require:
      - pkg: collectd-core
      - pkg: libsensors4

