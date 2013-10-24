#
# vsftpd installer
#

vsftpd:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: vsftpd
    - watch:
      - user: ftp

/etc/vsftpd.conf:
  file.managed:
    - source: salt://vsftpd/vsftpd.conf.jinja
    - template: jinja
    - context:
      users: {{ salt['pillar.get']('ftp:'+grains['id']+':users', 'False') }}
      anon: {{ salt['pillar.get']('ftp:'+grains['id']+':anon', 'False') }}
      write: {{ salt['pillar.get']('ftp:'+grains['id']+':write', 'False') }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: vsftpd
    - watch_in:
      - service: vsftpd

ftp:
  user.present:
    - require:
      - pkg: vsftpd
    - groups:
{%- for group in salt['pillar.get']('ftp:'+grains['id']+':groups', []) %}
      - {{ group }}
{% endfor %}

{% for name, dir in salt['pillar.get']('ftp:'+grains['id']+':anon_dirs', {}).items() %}
/srv/ftp/{{ name }}:
  mount.mounted:
    - device: {{ dir }}
    - mkmnt: True
    - fstype: none
    - opts:
      - defaults
      - bind
    - remount: False
    - require_in:
      - service: vsftpd
{% endfor %}
