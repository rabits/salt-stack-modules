#
# Users creation
#

{% for user, args in salt['pillar.get']('users', {}).items() %}
{{ user }}:
  group:
    - present
  user.present:
    - remove_groups: False
    - gid_from_name: True
{% if 'fullname' in args %}
    - fullname: {{ args['fullname'] }}
{% endif %}
{% if 'home' in args %}
    - home: {{ args['home'] }}
{% endif %}
{% if 'shell' in args %}
    - shell: {{ args['shell'] }}
{% endif %}
{% if 'password' in args %}
    - password: {{ args['password'] }}
{% if 'enforce_password' in args %}
    - enforce_password: {{ args['enforce_password'] }}
{% endif %}
{% endif %}
{% if 'groups' in args %}
    - groups:
{% if 'admin' in args and args['admin'] == True %}
      - sudo
      - adm
{% endif %}
{% for group in args['groups'] %}
      - {{ group }}
{% endfor %}
{% endif %}
    - require:
      - group: {{ user }}
 
{% if 'keys.pub' in args and args['keys.pub'] == True %}
{{ user }}_key.pub:
  ssh_auth:
    - present
    - user: {{ user }}
    - names: {{ args['keys.pub'] }}
{% endif %}
{% endfor %}
