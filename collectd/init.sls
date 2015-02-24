#
# Collectd monitor client
#

include:
  - sensors
{% if salt['additional.state_in'](['nginx']) %}
  - collectd.nginx
{% endif %}
{% if salt['additional.state_in'](['openvpn.server']) %}
  - collectd.openvpn
{% endif %}
{% if salt['additional.state_in'](['nut']) %}
  - collectd.nut
{% endif %}
{% if salt['additional.state_in'](['libvirt']) %}
  - collectd.libvirt
{% endif %}
{% if salt['additional.state_in'](['postgresql']) %}
  - collectd.postgresql
{% endif %}
{% if salt['additional.substring_search']('Radeon', grains['gpus']) %}
  - collectd.radeon
{% endif %}


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
    - require:
      - pkg: collectd-core

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

/etc/init/collectd.conf:
  file.managed:
    - source: salt://collectd/upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: collectd
    - require:
      - pkg: collectd-core

collectd:
  service.running:
    - require:
      - pkg: collectd-core
      - pkg: libsensors4
      - user: collectd
  user.present:
    - gid: {{ salt['file.group_to_gid']('nogroup') }}
    - shell: /bin/false
    - createhome: False
    - system: True
