# Virtualization Host Prerequisites

Verified installed on ibnb-Latitude-E7240 (hypervisor):

## Core packages
- qemu-system-x86 (+ qemu-utils, qemu-system-common) — VM execution backend
- libvirt-daemon-system — libvirt daemon + systemd integration
- libvirt-clients — virsh and CLI tooling
- virt-manager — GUI management, provides virt-viewer
- bridge-utils — legacy bridging tools (ip link/bridge command mostly used instead now)

## Install command (Ubuntu/Debian-family)
sudo apt install qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients virt-manager bridge-utils

## Post-install verification
virsh list --all          # confirms libvirt daemon is running and reachable
groups $(whoami)          # confirm your user is in the 'libvirt' group (needed for non-root virsh access)

## Notes
This documents what's actually installed on this host, verified via
`dpkg -l`, rather than assumed from memory. If rebuilding this hypervisor
from scratch, this is the real, minimum package set confirmed working.
