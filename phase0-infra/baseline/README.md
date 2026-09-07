# Baseline Captures
Two sets of baseline files exist here intentionally:
- `baseline-capture.pcap`, `baseline-iptables.txt` -- the original,
  manually captured Phase 0 baseline (predates the automation script,
  no timestamp in the filename).
- `baseline-ip-a-20260711-092718.txt`, `baseline-ip-neigh-20260711-092718.txt`,
  `baseline-ip-route-20260711-092718.txt`, `baseline-ss-20260711-092718.txt`,
  `baseline-virbr0-20260711-092718.pcap` -- the first successful run of
  `capture-baseline.sh`, kept as proof the automated capture produces
  equivalent, trustworthy output.
Future baseline runs should use `capture-baseline.sh` rather than manual
commands.
