# Recall Practice — Phase 1: ARP Cache / Stale Entry Diagnosis

TOPIC: Stale ARP Entries and Cache Correction
DATE STARTED: 2026-07-14
TARGET: answer all drills without checking reference — write the
        actual command you would type, not a description of it.

DRILL 12 — A host can't reach a peer it could reach minutes ago. You
suspect a stale ARP cache entry (e.g. the peer's NIC/MAC changed).
Write the command to check the current cached entry for that IP.
YOUR ANSWER:
>
REFERENCE:
ip neigh show <peer-ip>

DRILL 13 — You've confirmed the cached MAC for a peer doesn't match
reality. Write the exact command to remove that single stale entry
without rebooting or flushing the entire neighbor table.
YOUR ANSWER:
>
REFERENCE:
sudo ip neigh del <peer-ip> dev <interface>

DRILL 14 — After deleting a stale ARP entry, how do you force
immediate re-resolution instead of waiting for the next real traffic
attempt, and how do you confirm the new entry is correct?
YOUR ANSWER:
>
REFERENCE:
ping -c 1 <peer-ip>   (triggers a fresh ARP request)
ip neigh show <peer-ip>   (confirm new MAC matches the peer's real
interface, e.g. cross-check against `ip link show` on the peer)

SPEED ROUND — cover reference column, write the command aloud/on paper:

Check the cached MAC for a specific peer IP        -> ip neigh show <ip>
Delete one stale ARP entry, no reboot               -> sudo ip neigh del <ip> dev <if>
Force fresh ARP resolution after deleting an entry  -> ping -c 1 <ip>
Watch the actual ARP request/reply exchange         -> sudo tcpdump -i <if> -n -e arp

WEAK SPOT LOG:
Date       | What I got wrong | Fixed?
