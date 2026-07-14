# Baseline Captures

Two sets of baseline files exist here intentionally:

- `baseline-ip-a.txt`, `baseline-ip-neigh.txt`, `baseline-ip-route.txt`,
  `baseline-ss.txt`, `baseline-capture.pcap` -- the original, manually
  captured Phase 0 baseline (predates the automation script).
- `baseline-*-20260711-092718.*` -- the first successful run of
  `capture-baseline.sh`, kept as proof the automated capture produces
  equivalent, trustworthy output.

Future baseline runs should use `capture-baseline.sh` rather than manual
commands.
