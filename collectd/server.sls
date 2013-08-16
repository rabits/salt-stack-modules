#
# Collectd monitor server
#

include:
  - collectd
  - collectd.notify_email

{{ pillar['monitoring']['rrd_dir'] }}:
  file.directory:
    - user: root
    - group: www-data
    - mode: 750
    - makedirs: True
    - required_in:
      - service: collectd
