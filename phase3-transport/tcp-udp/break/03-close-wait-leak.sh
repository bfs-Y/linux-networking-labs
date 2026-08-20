#!/usr/bin/env bash
# Break: start a listener that accepts a connection and never closes
# it, simulating an application bug that leaks sockets in CLOSE_WAIT.
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
PORT=9999
echo "Host check: $(hostname)"
echo "Starting a listener on port ${PORT} that will never close its socket..."
python3 -c "
import socket, time
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('0.0.0.0', ${PORT}))
s.listen(1)
conn, addr = s.accept()
print('Connected:', addr)
time.sleep(300)
" &
LISTENER_PID=$!
echo "Listener PID: ${LISTENER_PID}"
sleep 1
echo "Triggering a connection that the listener will accept but never close..."
echo "test" | timeout 1 nc localhost ${PORT} || true
sleep 1
echo "Fault reproduced. Confirm with:"
echo "  ss -tan | grep ${PORT}"
echo "  (expect a CLOSE-WAIT entry - the listener accepted the"
echo "   connection but never called close())"
echo "Fix: ./phase3-transport/tcp-udp/fix/03-kill-stuck-listener.sh ${LISTENER_PID}"
