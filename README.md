Salt Stack Configuration
========================

This is configuration states for the [Salt Stack](http://saltstack.com/).
Base system is Ubuntu 12.04/13.04 - but I think it can be used for other deb-based distros (Debian, Mint etc).

Also you can find my bicycle solutions for backup, monitoring, webservers - some configurations can be difficult to understand (collectd), but it's working and I hope it will be helpful for you))

## Configs tree
I use next folder tree for states configuration (you can see it in salt/master config file)
/srv/salt:
 - .git - nodes configuration
 - pillar/
 - top.sls
 - master/ - you can clone it as submodule into your configuration
   - .git - this repo with configs
   - # generic config folders

## ../top.sls
Top config file with configuration of nodes example:
```yaml
#
# Main node manifest
#

master:
  '*':
    - users
    - net
    - openvpn.client
    - collectd
    - backup

  'kernel:Linux':
    - match: grain
    - ssh
    - vim
    - mc
    - kernel
    - salt
    - htop
    - git
    - byobu
    - zsh
    - zip
    - rar
    - 7zip
    - udev
    - ssmtp
    - smart
  
  'roles:desktop or roles:media':
    - match: compound
    - lightdm

  '<salt server nodename example>':
    - salt.master
    - collectd.server
    - openssl.ca
    - openvpn.server
    - nginx
    - jarmon
    - squid

  '<desktop nodename example>':
    - awesome
    - rxvt-unicode
    - smplayer
    - keepassx
    - firefox
    - thunderbird
    - transmission
    - gimp
    - skype
    - xonotic
    - steam
    - kvm
    - crypt
    - schroot
    - nmap
    - nut
    - simulator
    - razerhydra
```

## Minion grains
You could create grains in /etc/salt/grains in this format:
```yaml
#
# Minion roles
#  remote  - change ssh to non-default port & removes PasswordAuthentication from sshd_config, usualy for dedicated servers
#  desktop - enables X11 forwarding for ssh
#  server  - used in top.sls
#  media   - used in top.sls
#

roles:
  - remote
  - server
```

## Pillar
Please, be careful with pillar configuration - do not save it into main salt configuration.
You need to create next files:

../pillar/top.sls:
```yaml
#
# Configs
#

base:
  '*':
    - users
    - mail
    - ssl
    - openvpn
    - net
    - monitoring
    - backup
    - crypt
```

../pillar/backup.sls:
```yaml
#
# Backup hosts & settings
#

# Don't forget to initialize backup partitions as described in master/backup/init.sls

backup:
  <nodename>:
    keyfile: <path to file with cryptsetup luks password>
    disk: <path to encrypted partition>
    folders:
      - <folder to backup>
      - <folder to backup>
  <nodename>:
    keyfile: /home/backup.key
    disk: /dev/sdb
    folders:
      - /home
      - /etc
```

../pillar/mail.sls:
```yaml
#
# Mail configuration
#

mail:
  account:  <account>@gmail.com
  server:   smtp.gmail.com
  port:     587
  password: <account password>
  admin:    <email of administrator>
```

../pillar/monitoring.sls
```yaml
#
# Monitoring configuration
#  rrd_dir - place for rrd files of collectd
#  stat_dir - place for jarmon
#  port - collectd client & server port
#

monitoring:
  rrd_dir:  /srv/rrd
  stat_dir: /srv/stat
  port:     4940
```

../pillar/net.sls
```yaml
#
# Internal VPN Network
#

net:
  main_domain: <main domain of network like example.com>
  ssh_port: {{ '222' if 'remote' in grains['roles'] else '22' }}
  hosts:
    <nodename>:
      vpnserver: True
      monitorserver: True
      hidden: True
      server: True
      ip: 10.10.0.1

    <nodename>:
      server: True
      aliases:
        - <some alias for node in /etc/hosts>
      ip: 10.10.0.10
```

../pillar/openvpn.sls
```yaml
#
# OpenVPN configs
#  host - vpn server dns
#  port - vpn server port
#  ccd - folder for client configurations
#

openvpn:
  host: <vpn server dns>
  port: 1194
  ccd: /etc/openvpn/ccd

../pillar/ssl.sls:
```yaml
#
# OpenSSL & CA settings
#

ssl:
  home:      '/srv/ssl'
  ca:        '/srv/ssl/ca'
  ca_config: '/srv/ssl/ca/ca.config'
  ca_crt:    '/srv/ssl/ca/ca.crt'
  ca_key:    '/srv/ssl/ca/ca.key'
  crl:       '/srv/ssl/ca/crl.pem'
  crls:      '/srv/ssl/crls'
  csrs:      '/srv/ssl/csrs'
  certs:     '/srv/ssl/certs'
  newcerts:  '/srv/ssl/newcerts'
  keys:      '/srv/ssl/keys'
```

../pillar/users.sls:
```yaml
#
# Users
#

users:
  <username>:
    fullname: <user full name>
    shell: /bin/bash
    admin: True
    groups:
      - cdrom
      - dip
      - plugdev
    keys.pub:
      - <ssh public key string "ssh-rsa ...">
```

../pillar/crypt.sls:
```yaml
#
# Crypt automount folders on login configuration
# Format:
#   <nodename>:
#     <user>:
#       <folder>: <disk>
#

crypt:
  <nodename>:
    user:
      /home/user: /dev/mapper/vg-home-user
```
