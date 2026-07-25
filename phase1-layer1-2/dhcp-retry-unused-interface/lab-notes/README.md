# Lab Notes: Interface State - DHCP on a Network With No DHCP

## Objective
Diagnose why an interface repeatedly attempts DHCP and never gets an
address, when the actual cause is a NetworkManager config mismatch
against the intended design of the attached network - not a broken
network.

## Investigation sequence
    nmcli device status
Look for a device stuck in "connecting (getting IP configuration)"
rather than "connected" or "disconnected" - that's the DHCP-retry
signature.

    virsh domiflist <vm>
Confirms which libvirt network each interface is actually attached
to (e.g. default vs isolated).

    virsh net-dumpxml <network-name>
Check for an <ip>/<dhcp> section. No DHCP section means that network
was never designed to hand out addresses - a client configured for
DHCP on it will retry forever by design, not by fault.

    ps aux | grep dnsmasq
Confirms which libvirt networks actually have a running DHCP server
(dnsmasq instance) on the hypervisor. A network with no dnsmasq
process cannot answer DHCP requests, regardless of client config.

    nmcli connection show "<connection-name>"
Check ipv4.method (auto = DHCP) and connection.autoconnect on the
guest side - this is where the actual mismatch usually lives.

## Root cause pattern
The interface's NetworkManager profile assumed DHCP would be
available (ipv4.method: auto, autoconnect: yes) on a libvirt network
that was intentionally provisioned without a DHCP server. This is a
config/design mismatch, not a network fault - the network worked
exactly as provisioned.

## Fix
    nmcli connection modify "<connection-name>" connection.autoconnect no
Disables automatic activation on an interface not meant to be used
yet, until the network is redesigned to provide DHCP or a static
address is configured instead.

## Lesson
Before treating a missing DHCP lease as a fault, verify the network
was actually designed to provide DHCP at all (net-dumpxml + dnsmasq
process check). A missing lease can be entirely expected behavior on
an intentionally isolated or static-only network.
