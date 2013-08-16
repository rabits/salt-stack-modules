#
# XEN hypervisor
#

include:
  - libvirt

xen-pkgs:
  pkg.installed:
    - pkgs:
      - xen-hypervisor-4.2-amd64
      - xen-utils-4.2
      - xenwatch
      - xen-tools

network-manager:
  pkg.removed

/etc/grub.d/09_linux_xen:
  file.rename:
    - source: /etc/grub.d/20_linux_xen
    - require:
      - pkg: xen-pkgs

/usr/lib/xen-default:
  file.symlink:
    - target: /usr/lib/xen-4.2
    - require:
      - pkg: xen-pkgs

/etc/default/grub:
  file.sed:
    - before: 0
    - after: 5
    - limit: '^GRUB_HIDDEN_TIMEOUT='
  file.sed:
    - before: '""'
    - after: '"max_loop=64 xen-pciback.permissive xen-pciback.hide=(01:00.0)(01:00.1) dom0_mem=8192M dom0_max_vcpus=4 intel_iommu=on"'
    - limit: '^GRUB_CMDLINE_LINUX='

update-grub:
  cmd.wait:
    - watch:
      - file: /etc/default/grub
      - file: /etc/grub.d/09_linux_xen

/srv/xen:
  file.directory:
    - user: root
    - group: libvirtd
    - mode: 750
    - require:
      - pkg: xen-pkgs

/etc/modules:
  file.append:
    - text:
      - xen-pciback passthrough=1

/etc/network/interfaces:
  file.managed:
    - source: salt://xen/interfaces
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: xen-pkgs
