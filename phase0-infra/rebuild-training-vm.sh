#!/bin/bash
# Draft virt-install command to reproduce training-vm from scratch.
# NOT YET TESTED — verify against a differently-named test VM first.

virt-install \
  --name training-vm-test \
  --memory 4096 \
  --vcpus 2 \
  --disk size=30,format=qcow2 \
  --os-variant ubuntu24.04 \
  --network network=default \
  --graphics spice \
  --cdrom /path/to/ubuntu-24.04-desktop-amd64.iso
