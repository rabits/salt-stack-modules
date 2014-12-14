{% import 'openssl/vars.sls' as ssl with context %}

{% set autorun = salt['pillar.get']('net:hosts:%s:vpn'|format(grains['id']), 'no') -%}
{% set instance = salt['pillar.get']('net:hosts:%s:vpn'|format(grains['id']), 'client') -%}

{% set host = salt['pillar.get']('openvpn:host', 'localhost') -%}
{% set port = salt['pillar.get']('openvpn:port', '1194') -%}
{% set ccd  = salt['pillar.get']('openvpn:ccd', '/etc/openvpn/ccd') -%}

{% set ip = salt['pillar.get']('openvpn:ip', '192.168.0.1') %}
{% set net = salt['pillar.get']('openvpn:net', '192.168.0.0') %}
{% set mask = salt['pillar.get']('openvpn:mask', '255.255.255.0') %}

{% set ta   = ssl.home + '/openvpn_ta.key' -%}
{% set key  = ssl.keys + '/openvpn.key' -%}
{% set cert = ssl.certs + '/openvpn.crt' -%}
{% set csr  = ssl.csrs + '/openvpn.csr' -%}
