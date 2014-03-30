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
      - group: rstream
      - file: /srv/streams

/srv/streams/conf:
  file.directory:
    - user: root
    - group: rstream
    - mode: 750
    - require:
      - group: rstream
      - file: /srv/streams

/srv/streams/log:
  file.directory:
    - user: rstream
    - group: rstream
    - mode: 755
    - require:
      - user: rstream
      - file: /srv/streams/archive

{% for stream, data in salt['pillar.get']('rstream:streams', {}).items() %}
{% if 'view' in data %}
/srv/streams/{{ data['name'] }}.strm:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: {{ data['view'] }}
    - require:
      - file: /srv/streams
{% endif %}

{% if 'stream-from' in data %}
/srv/streams/conf/rstream-{{ stream }}.ini:
  file.managed:
    - source: salt://rstream/config.ini.jinja
    - template: jinja
    - user: root
    - group: rstream
    - mode: 640
    - context:
      stream: {{ stream }}
    - require:
      - file: rstream
      - group: rstream
      - file: /srv/streams/conf
      - file: /srv/streams/log

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
      - file: /srv/streams/conf/rstream-{{ stream }}.ini
      - file: /srv/streams/archive

rstream-{{ stream }}:
  service.running:
    - require:
      - user: rstream
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
