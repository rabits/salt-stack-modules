#
# rStream Video Digital Recorder
#

{% from 'monit/macros.sls' import monit with context %}

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
    - groups:
      - audio
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
    - user: rstream
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
      - file: /srv/streams

/srv/streams/live:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - user: rstream
      - file: /srv/streams

{% for stream, data in salt['pillar.get']('rstream:streams', {}).items() %}
{% if 'view' in data %}
/srv/streams/live/{{ data['name'] }}.strm:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: {{ data['view'] }}
    - require:
      - file: /srv/streams/live
{% endif %}

{% if 'stream-to' in data %}
{%- set stream_to_ip = data['stream-to'].split(':')[0] %}
{%- set stream_to_port = data['stream-to'].split(':')[1]|int() %}
/srv/streams/live/{{ data['name'] }}.sdp:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
        v=0
        c=IN IP4 {{ stream_to_ip }}
        m=video {{ stream_to_port }} RTP/AVP 96
        a=rtpmap:96 H264/90000
        m=audio {{ stream_to_port + 2 }} RTP/AVP 97
        a=rtpmap:97 MP4A-LATM/44100
    - require:
      - file: /srv/streams/live
{% endif %}

{% if 'stream-from' in data %}
/srv/streams/conf/rstream-{{ stream }}.ini:
  file.managed:
    - source: salt://rstream/config.ini.jinja
    - template: jinja
    - user: rstream
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
      run_user: rstream
      run_group: {{ 'audio' if 'audio' in data else 'rstream' }}
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

{{ monit('rstream', '', stream) }}

/srv/bin/rstream-check-{{ stream }}-archive.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - contents: |
        #!/bin/sh
        /usr/bin/test "$(/usr/bin/find "{{ salt['pillar.get']('rstream:streams:%s:output-dir'|format(stream), 'None') }}" -type f -mmin -5)"
        exit $?
    - require:
      - file: /srv/bin
    - require_in:
      - service: monit
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
