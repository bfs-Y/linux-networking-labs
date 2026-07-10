#!/bin/bash
# virt-install command to reproduce a training VM equivalent to training-vm.
# Dry-run validated (syntax/parameters confirmed correct against libvirt).
# NOT yet tested with a full OS install — that's the remaining verification
# step, deferred due to time cost (~20+ min for interactive install).

virt-install \
  --name training-vm-test \
  --memory 4096 \
  --vcpus 2 \
  --disk size=30,format=qcow2 \
  --os-variant ubuntu24.04 \
  --network network=default \
  --graphics spice \
  --cdrom /home/ibnb/Downloads/ubuntu-24.04.3-desktop-amd64.iso
