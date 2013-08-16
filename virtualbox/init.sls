#
# VirtualBox vitual machine
#

virtualbox:
  pkg.installed

/etc/modules:
  file.append:
    - text:
      - pci-stub

/etc/default/grub:
  file.sed:
    - before: '""'
    - after: '"intel_iommu=on"'
    - limit: '^GRUB_CMDLINE_LINUX='

update-grub:
  cmd.wait:
    - watch:
      - file: /etc/default/grub
