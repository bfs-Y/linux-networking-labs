# Training Environment Topology
## Host
- Hostname: ibnb-Latitude-E7240
- Hypervisor: KVM/libvirt
## VMs
- **training-vm** (renamed from `ubuntu-desktop`) — primary training VM
  - Guest hostname: training-Ubuntu-24-04-PC-Q35-ICH9-2009
  - RAM: 4096 MiB, vCPU: 2
  - Disk: qcow2, /var/lib/libvirt/images/ubuntu-desktop.qcow2
  - Networks:
    - net0: `default` network, bridge `virbr0`, NAT, IP 192.168.122.227/24 (active use)
    - net1: `isolated` network, bridge `virbr1`, no IP/DHCP configured (unused — see BACKLOG.md)
-## Notes
- All break/fix/harden lab scripts run inside training-vm, never on the host.
- virt-install origin not documented (VM was created via AI-assisted setup);
  reconstructing a reproducible virt-install command is a Phase 0 backlog item.
