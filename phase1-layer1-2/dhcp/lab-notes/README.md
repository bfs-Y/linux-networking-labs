# Lab Notes — DHCP Pool Range Awareness

## Environment
Tested on ubuntulab (Ubuntu 24.04.4, enp1s0, 192.168.122.227) against
libvirt's `default` network (192.168.122.0/24, DHCP range .2-.254).

## Why this scenario
A manually-assigned static IP colliding with a DHCP pool is a real,
common operational mistake — no attacker involved, just a config gap
between "what an admin assigns by hand" and "what DHCP is actively
managing." Chosen specifically because it's the kind of subtle,
intermittent bug that's hard to diagnose in production (the conflict
may not surface immediately — only when DHCP actually hands out the
colliding address to another host).

## Caveats
- This lab only demonstrates the RISK (a secondary IP inside the pool
  range) — it does not simulate the actual conflict moment (two hosts
  claiming the same IP simultaneously). That would require a second VM
  actually receiving that exact address via DHCP, which is timing-
  dependent and not easily forced on demand.
- Real DHCP lease data can be cross-referenced at
  /var/lib/libvirt/dnsmasq/virbr0.status if you want to confirm the
  pool's current assignments before running this lab again.

## Not yet covered (see BACKLOG.md)
- Actual DORA process observation via tcpdump (DISCOVER/OFFER/REQUEST/ACK)
- Lease renewal/expiry timing behavior

## DORA observation — actual result (2026-07-27)
Captured a REQUEST/ACK renewal exchange (not full DISCOVER/OFFER/REQUEST/ACK)
since the client already held a lease. Real evidence from the ACK packet:
Lease-Time=3600s, RN(T1)=1800s (50%), RB(T2)=3150s (87.5%) — confirms
textbook DHCP renewal timing with actual captured values, not just theory.
To see a full DISCOVER/OFFER exchange, a genuinely fresh client (new MAC,
never leased before) would be needed — not yet attempted.
