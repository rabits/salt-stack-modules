#
# rStream video server
#

rstream:
  pkg.installed:
    pkgs:
      - python-gi
      - gir1.2-gstreamer-1.0
      - gstreamer1.0-libav
      - gstreamer1.0-plugins-base
      - gstreamer1.0-plugins-good
      - gstreamer1.0-plugins-bad
      - gstreamer1.0-plugins-ugly
  file.managed:
    - name: /usr/local/bin/rstream.py
    - source: salt://rstream/src/rstream.py
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: rstream
  group:
    - present
  user.present:
    - gid: {{ salt['file.group_to_gid']('rstream') }}
    - require:
      - group: rstream

/srv/streams:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - clean: True

/srv/streams/archive:
  file.directory:
    - user: rstream
    - group: rstream
    - mode: 755
    - require:
      - file: /srv/streams

/srv/streams/archive/log:
  file.directory:
    - user: rstream
    - group: rstream
    - mode: 755
    - require:
      - file: /srv/streams/archive

{% for stream, data in pillar['rstream']['streams'].items() %}
/srv/streams/{{ data['name'] }}.strm:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - replace: False
    - contents: {{ data['url'] }}

{% if data['save'] %}
/etc/init/rstream-{{ stream }}.conf:
  file.managed:
    - source: salt://rstream/upstart.conf.jinja
    - template: jinja
    - context:
      stream: {{ stream }}
    - user: root
    - group: root
    - mode: 644

rstream-{{ stream }}:
  service.running:
    - require:
      - user: rstream
      - file: /srv/streams/archive/log
    - watch:
      - file: /etc/init/rstream-{{ stream }}.conf
      - file: rstream
{% endif %}
{% endfor %}
