#
# Collectd monitor server
#

include:
  - collectd
  - collectd.notify_email

{{ salt['pillar.get']('monitoring:rrd_dir', '/srv/rrd') }}:
  file.directory:
    - user: root
    - group: www-data
    - mode: 750
    - makedirs: True
    - required_in:
      - service: collectd
