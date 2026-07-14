# Postmortem

Date: 2026-07-10

Lab: Phase 1 -- DHCP retry loop on intentionally-unused isolated-network interface

## Symptom (verbatim command and output)

Command:
nmcli device status

Output:
DEVICE   TYPE      STATE                                  CONNECTION
enp1s0   ethernet  connected                              netplan-enp1s0
enp7s0   ethernet  connecting (getting IP configuration)  Wired connection 1
lo       loopback  connected (externally)                 lo
docker0  bridge    connected (externally)                 docker0

## Root Cause

Both training-vm and centos9 were configured to automatically obtain an
IPv4 address on enp7s0 (ipv4.method=auto), but that interface was attached
to the libvirt isolated network, which intentionally provided neither an
IP configuration nor a DHCP server.

## Evidence

- virsh domiflist training-vm showed enp1s0 attached to the default
  network, enp7s0 attached to the isolated network.
- virsh net-dumpxml isolated contained no <ip> or <dhcp> section.
- ps aux | grep dnsmasq showed dnsmasq running only for the default and
  training-lab networks, not for isolated.
- On both training-vm and centos9, Wired connection 1 was configured with
  connection.interface-name: enp7s0, connection.autoconnect: yes,
  ipv4.method: auto.
- NetworkManager therefore attempted DHCP on an interface connected to a
  network that could never issue a lease.

## What Changed vs What Stayed the Same

Changed:
- connection.autoconnect for Wired connection 1 changed from yes to no on
  both training-vm and centos9.
- On both VMs, enp7s0 changed from repeatedly attempting DHCP to an
  intentionally disconnected state.

Stayed the same:
- The libvirt isolated network configuration was not modified.
- No DHCP server was added.
- enp1s0 on both VMs remained connected to the default network and
  continued operating normally with DHCP.

## Fix Applied

Disabled automatic activation of the unused enp7s0 connection on both
virtual machines.

training-vm:
nmcli connection modify "Wired connection 1" connection.autoconnect no

Verification:
DEVICE   TYPE      STATE          CONNECTION
enp7s0   ethernet  disconnected   --

centos9:
nmcli connection modify "Wired connection 1" connection.autoconnect no

Verification (hostname-confirmed on centos9):
DEVICE  TYPE      STATE          CONNECTION
enp7s0  ethernet  disconnected   --

## Automated or Permanent Version of the Fix

Treat enp7s0 as an intentionally unused interface until a future lab
requires the isolated network. Disable automatic activation on both
virtual machines to prevent unnecessary DHCP attempts. When the isolated
network is later required, either configure a static IPv4 address on
enp7s0 or redesign the libvirt network to provide DHCP if automatic
address assignment is desired.

## Detection Gap

The initial assumption was that a missing DHCP lease indicated a
networking fault. The actual issue was a mismatch between the VM's
NetworkManager configuration and the intended design of the attached
libvirt network. The investigation became conclusive only after
correlating NetworkManager connection profiles inside both virtual
machines, the libvirt network definition for isolated, and active
dnsmasq instances on the hypervisor.

Operational rule: before treating a missing DHCP lease as a fault,
verify that the network is actually designed to provide DHCP.
