#!/usr/bin/env bash
# Fix: kill the stuck listener process that's leaking a CLOSE_WAIT
# socket, releasing it. This is the realistic production remediation
# for a leaked-socket bug - restart the process, then fix the actual
# application code separately (out of scope for a shell fix).
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
PID="${1:-}"
PORT=9999
echo "Host check: $(hostname)"
if [ -z "${PID}" ]; then
    echo "No PID given, searching for the listener on port ${PORT}..."
    PID=$(sudo lsof -ti tcp:${PORT} -sTCP:LISTEN 2>/dev/null || true)
fi
if [ -z "${PID}" ]; then
    echo "No listener found on port ${PORT} - nothing to fix."
    exit 0
fi
echo "Killing stuck listener PID ${PID}..."
kill "${PID}" 2>/dev/null || echo "(already gone)"
sleep 1
echo "Verifying:"
ss -tan | grep "${PORT}" || echo "Confirmed clean - no sockets remain on port ${PORT}"
echo "Fix applied. Note: this only clears the symptom - the real fix is"
echo "correcting the application code to call close() on its sockets."
