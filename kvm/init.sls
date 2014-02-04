#
# KVM hypervisor
#
# VGA Passthrough: i7 3770 Asrock Extreme 4
#   - BIOS:
#     - Enable IOMMU
#     - Enable default video: pci-express (not onboard)
#     - Enable IGPU MultiMonitor
#   - Host:
#     - Create /etc/X11/xorg.conf.d/intel.conf:
#       - Driver "intel"
#       - BusID "PCI:0:2:0"
#     - 3.9x kernel: git://github.com/awilliam/linux-vfio.git vfio-vga-reset
#     - Qemu 1.5.0: git://github.com/awilliam/qemu-vfio.git vfio-vga-reset
#     - SeaBios: git://git.seabios.org/seabios.git (build it with `LANG="en_US.utf8" make`)
#
#   Testing:
#     - Bind VGA to vfio-pci:
#       $ sudo vfio-bind 0000:01:00.0 0000:01:00.1
#     - Run:
#       $ sudo qemu-system-x86_64 -enable-kvm -M q35 -m 4096 -cpu host -smp 4,sockets=1,cores=2,threads=2 -bios /srv/kvm/seabios/bios.bin -vga none -nographic -device ioh3420,bus=pcie.0,addr=1c.0,multifunction=on,port=1,chassis=1,id=root.1 -device vfio-pci,host=01:00.0,bus=root.1,addr=00.0,multifunction=on,x-vga=on -boot menu=on -monitor stdio
#     - Switch to your second VGA and you should see bios
#

include:
  - libvirt

kvm-pkgs:
  pkg.installed:
    - pkgs:
      - qemu-kvm
      - qemu-system
      - bridge-utils
      - python-spice-client-gtk
      - pm-utils

network-manager:
  pkg.removed

/srv/kvm:
  file.directory:
    - user: root
    - group: libvirtd
    - mode: 755
    - require:
      - pkg: kvm-pkgs

/usr/local/bin/vfio-bind:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://kvm/vfio-bind
    - require:
      - pkg: kvm-pkgs

/etc/default/grub:
  file.sed:
    - before: 0
    - after: 5
    - limit: '^GRUB_HIDDEN_TIMEOUT='
#  file.sed:
#    - before: '""'
#    - after: '"intel_iommu=on"'
#    - limit: '^GRUB_CMDLINE_LINUX='

#/etc/modprobe.d/vfio_iommu_type1.conf:
#  file.managed:
#    - user: root
#    - group: root
#    - mode: 644
#    - contents: options vfio_iommu_type1 allow_unsafe_interrupts=1
#    - require:
#      - pkg: kvm-pkgs

/etc/network/interfaces:
  file.managed:
    - source: salt://kvm/interfaces
    - user: root
    - group: root
    - mode: 644
    - replace: False
    - require:
      - pkg: kvm-pkgs
