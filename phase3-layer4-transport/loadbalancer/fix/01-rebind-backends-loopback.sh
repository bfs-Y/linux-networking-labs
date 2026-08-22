#!/bin/bash
# Fix 01: Detect backend processes bound to the wrong interface and correct them
# Pairs with: break/01-loadbalancer-setup.sh
# Real defect this repairs: python3 -m http.server defaults to binding 0.0.0.0
# (all interfaces) unless -b is passed. A backend bound to 0.0.0.0 is directly
# reachable from the network, bypassing the load balancer entirely - this
# script detects that state and repairs it in place, without assuming which
# PID currently holds the port.

set -u

PORTS=(8081 8082)
DIRS=(~/lb-test/server1 ~/lb-test/server2)

for i in "${!PORTS[@]}"; do
    PORT="${PORTS[$i]}"
    DIR="${DIRS[$i]}"

    echo "[CHECK] Port ${PORT}:"
    BIND_LINE=$(sudo ss -tulnp | grep ":${PORT} ")

    if [ -z "$BIND_LINE" ]; then
        echo "  Nothing listening on ${PORT}. Starting it fresh, bound to 127.0.0.1."
        cd "$DIR" && python3 -m http.server "$PORT" -b 127.0.0.1 &
        disown
        continue
    fi

    echo "  $BIND_LINE"

    if echo "$BIND_LINE" | grep -q "127.0.0.1:${PORT}"; then
        echo "  Already correctly bound to 127.0.0.1 - no action needed (idempotent)."
        continue
    fi

    if echo "$BIND_LINE" | grep -q "0.0.0.0:${PORT}"; then
        echo "  DEFECT FOUND: bound to 0.0.0.0 (all interfaces). Repairing."
        PID=$(echo "$BIND_LINE" | grep -oP 'pid=\K[0-9]+' | head -1)
        if [ -z "$PID" ]; then
            echo "  ERROR: could not extract PID from ss output. Manual intervention required."
            continue
        fi
        echo "  Killing PID ${PID} (bound to 0.0.0.0:${PORT})..."
        sudo kill "$PID"
        sleep 1
        # Confirm the kill actually worked before relaunching - don't assume
        if sudo ss -tulnp | grep -q ":${PORT} "; then
            echo "  ERROR: port ${PORT} still held after kill. Aborting relaunch for this port."
            continue
        fi
        echo "  Relaunching on ${PORT}, bound to 127.0.0.1..."
        cd "$DIR" && python3 -m http.server "$PORT" -b 127.0.0.1 &
        disown
        sleep 1
        echo "  Post-fix state:"
        sudo ss -tulnp | grep ":${PORT} "
    fi
done

echo ""
echo "[DONE] Re-check full state for both ports:"
sudo ss -tulnp | grep -E "8081|8082"
