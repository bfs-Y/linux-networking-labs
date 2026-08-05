# Lab Notes: IP Addressing and CIDR Fundamentals

This topic didn't click on the first pass through the math. Took a
full rebuild from scratch, slower than usual, using plain analogies
instead of formulas, before any of it actually stuck. Writing it up
the way it was actually understood, not the way a textbook would.

## Starting point: what an IP address even is
An IP address is just a unique address for a device - same idea as a
house address on a street. Nothing more complicated than that at the
base.

## What a subnet is
A subnet is a small "neighborhood" of addresses grouped together on
purpose. Devices inside the same neighborhood can reach each other
directly. Devices in a different neighborhood need to go through a
router first - same as needing to get onto a connecting road to reach
a different street.

## Where /28 actually comes from
An IP address is built from 32 "slots," each either 0 or 1. The number
after the slash says how many of those 32 slots are locked in as the
network's own identity. Whatever's left over is used to count
individual devices.

/28 -> 32 - 28 = 4 slots left over for counting devices

## Why 4 leftover slots means 16 addresses
This is the part that took the most rebuilding. The rule: each extra
free slot DOUBLES how many things you can count - same as doubling a
pile of apples. 1 slot = 2. 2 slots = 4. 3 slots = 8. Doubling 8 (for
the 4th slot) took a couple of wrong guesses (32, then correctly
walking it through as "8 apples plus another 8 apples") before landing
on the right answer: 16.

/28 -> 4 free slots -> 16 total addresses

## Why only 14 of those 16 are actually usable
Every subnet, no matter the size, always loses exactly 2 addresses:
- The FIRST one is the network's own name/identity - not a device.
- The LAST one is a special "shout to everyone" address (broadcast) -
  also not a device.

16 total - 2 reserved = 14 usable addresses for real devices.

## How consecutive /28 blocks are laid out
They sit back-to-back, no gaps, each one starting exactly 16 higher
than the last - because each block is 16 addresses wide:

10.50.0.0/28   -> .0  - .15   (usable: .1-.14)
10.50.0.16/28  -> .16 - .31   (usable: .17-.30)
10.50.0.32/28  -> .32 - .47   (usable: .33-.46)
10.50.0.48/28  -> .48 - .63   (usable: .49-.62)

Getting from block 3's start (32) to block 4's start took breaking
32+16 into two smaller steps (32+10, then +6) rather than doing it in
one jump - and that was fine, that's what actually got the right
answer (48) instead of a wrong guess.

## Same-subnet vs cross-subnet, tied back to the original scenario
Original task: carve a /28 out of 10.50.0.0/24 for four VMs.
- Two VMs inside that same /28 (e.g. 10.50.0.1 and 10.50.0.5) talk
  directly, no router needed.
- A VM in that /28 reaching something outside it (e.g. 10.50.1.100)
  has to go through a router/gateway.

That's the actual reason to deliberately carve a small subnet for a
group of VMs in the first place - not just to organize addresses, but
to control and separate traffic between groups on purpose.

## Lesson
The math wasn't the hard part once broken down small enough - the hard
part was trying to absorb it all at once from a formula instead of
building it one plain idea at a time. Doubling and simple addition, in
small steps, got to the same correct answers that abstract explanation
didn't land the first several times.
