#
# S3QL - aws s3 fuse file system
#

s3ql-repo:
  pkgrepo.managed:
   - ppa: nikratio/s3ql
   - required_in:
     - pkg: s3ql

s3ql:
  pkg.installed

{% for name, args in salt['pillar.get']('s3ql:%s'|format(grains['id']), {}).items() -%}
{{ args.auth.file }}:
  file.managed:
    - user: {{ args.user }}
    - group: {{ args.group }}
    - mode: 600
    - contents: |
        [{{ name }}]
        storage-url: {{ args.url }}
        backend-login: {{ args.auth.login }}
        backend-password: {{ args.auth.password }}
    - require:
      - pkg: s3ql

{{ args.cachedir }}:
  file.directory:
    - user: {{ args.user }}
    - group: {{ args.group }}
    - mode: 700
    - makedirs: True
    - require:
      - pkg: s3ql

/etc/init/s3ql-{{ name }}.conf:
  file.managed:
    - source: salt://s3ql/upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      required_for: {{ args.required_for|default(None) }}
      runuser: {{ args.user }}
      rungroup: {{ args.group }}
      url: {{ args.url }}
      dir: {{ args.dir }}
      cachedir: {{ args.cachedir }}
      authfile: {{ args.auth.file }}
    - require:
      - pkg: s3ql
      - file: {{ args.auth.file }}
      - file: {{ args.cachedir }}
    - required_in:
      - service: s3ql-{{ name }}

s3ql-{{ name }}:
  service.running
{% endfor %}
