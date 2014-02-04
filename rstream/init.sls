#
# rStream Video Digital Recorder
#

rstream:
  pkg.installed:
    - pkgs:
      - python-gi
      - gir1.2-gstreamer-1.0
      - gstreamer1.0-libav
      - gstreamer1.0-plugins-base
      - gstreamer1.0-plugins-good
      - gstreamer1.0-plugins-bad
      - gstreamer1.0-plugins-ugly
      - gstreamer1.0-alsa
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
    - gid_from_name: True
    - require:
      - group: rstream

/srv/streams:
  file.directory:
    - user: root
    - group: root
    - mode: 755

/srv/streams/archive:
  file.directory:
    - user: rstream
    - group: rstream
    - mode: 755
    - require:
      - user: rstream
      - file: /srv/streams

/srv/streams/archive/log:
  file.directory:
    - user: rstream
    - group: rstream
    - mode: 755
    - require:
      - user: rstream
      - file: /srv/streams/archive

{% for stream, data in salt['pillar.get']('rstream:streams', {}).items() %}
/srv/streams/{{ data['name'] }}.strm:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: {{ data['url'] }}
    - require:
      - file: /srv/streams

{% if data['save'] %}
/etc/init/rstream-{{ stream }}.conf:
  file.managed:
    - source: salt://rstream/upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      stream: {{ stream }}
    - require:
      - file: rstream
      - file: /srv/streams/archive

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

/usr/local/sbin/rstream_freespace.sh:
  file.managed:
    - source: salt://rstream/rstream_freespace.sh
    - user: root
    - group: root
    - mode: 750
    - require:
      - file: rstream
      - file: /srv/streams/archive

/usr/local/sbin/rstream_freespace.sh 2>&1 | /usr/bin/logger -t ARCHIVE:
  cron.present:
    - user: root
    - minute: 0
    - hour: 4
    - require:
      - file: /usr/local/sbin/rstream_freespace.sh
