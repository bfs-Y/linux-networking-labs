# Lab Notes: MTU Mismatch (enp1s0, centos9 vs training-vm)

## Objective
Confirm and reproduce an MTU mismatch between training-vm (Ubuntu
24.04) and centos9 (CentOS Stream 9), distinguishing it from a
symptom that looks similar (large transfers "hanging") but has no
real MTU fault.

## Investigation baseline (no fault present)
    ip link show enp1s0   # on both hosts - confirm configured MTU
    ping -M do -s 1472 -c 4 <peer-ip>   # DF-bit set, sized to exactly
                                          # the 1500-byte MTU boundary
0% loss here means full-size packets pass unfragmented end-to-end -
no MTU fault exists. A real large transfer (scp of a multi-hundred-MB
file, from training-vm (Ubuntu 24.04) to centos9 (CentOS Stream 9))
completing without stalling further confirms this.

## Reproducing a real mismatch
    ./phase1-layer1-2/mtu/break/01-lower-mtu-mismatch.sh
    # run on centos9 (CentOS Stream 9)
Lowers centos9's enp1s0 MTU to 1400, saving the original value to
/tmp/enp1s0-original-mtu first.

Confirm the break:
    ip link show enp1s0
    # on centos9 (CentOS Stream 9), mtu 1400
    ping -M do -s 1472 -c 4 <centos9-ip>
    # from training-vm (Ubuntu 24.04) - should now fail
    # (packet too large, DF bit set)
A plain, small ping still succeeds - this is the signature that
separates an MTU fault from a total connectivity failure.

## Fix
    ./phase1-layer1-2/mtu/fix/01-restore-mtu.sh
    # run on centos9 (CentOS Stream 9)
Restores the saved original MTU exactly, rather than assuming 1500.

Verify:
    ping -M do -s 1472 -c 4 <centos9-ip>
    # from training-vm (Ubuntu 24.04), succeeds

## Lesson
Small packets succeeding while large/sustained transfers fail is the
classic MTU-mismatch signature - but "looks like MTU" and "is MTU"
are different claims. Always test with a DF-bit ping sized to the
exact MTU boundary before concluding an MTU fault exists; don't
diagnose from symptom description alone.
