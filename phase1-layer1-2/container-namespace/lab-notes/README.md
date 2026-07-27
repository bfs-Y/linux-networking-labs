# Lab Notes: Container Network Namespace Isolation

## Objective
Observe how a container runtime (Docker) uses the same kernel primitives
as the manual bridge/veth/namespace work in phase1-layer1-2/bridging/,
just automated. Confirm namespace isolation, host-side bridging, and
clean teardown.

## Procedure

### 1. Start a container (creates the namespace)
    ./phase1-layer1-2/container-namespace/break/01-container-namespace.sh
Runs:
    sudo docker run -d --name test-container nginx
Docker automatically:
- Creates a new network namespace for the container's process.
- Creates a veth pair, one end inside the namespace, one end attached
  to the host's docker0 bridge.
- Assigns the container a private IP inside its own namespace.

### 2. Verify isolation
    sudo docker ps | grep test-container
    sudo docker inspect test-container | grep -A 5 '"IPAddress"'
    ip a show docker0
Confirms: container is running, has its own private IP distinct from
the host's addressing, and docker0 reflects the new attachment.

### 3. Clean teardown
    ./phase1-layer1-2/container-namespace/fix/01-container-cleanup.sh
Runs:
    sudo docker stop test-container
    sudo docker rm test-container
Verify:
    sudo docker ps -a | grep test-container || echo "Confirmed clean"
    ip a show docker0
Confirms the container, its namespace, and its veth attachment are
fully removed; docker0 returns to idle.

## Mechanism (same as bridging/, automated)
Container process -> own network namespace -> veth pair
                                                  |
                                          host end -> docker0 bridge

This is structurally identical to the manual veth + namespace + bridge
setup built in phase1-layer1-2/bridging/ - a container runtime just
automates the creation, attachment, and teardown steps that were done
by hand there.

## Lesson
Container network isolation is not a separate technology from what you
already built manually - it's the same kernel namespace/veth/bridge
primitives, wrapped in tooling. Understanding the manual version removes
the "magic" from what `docker run` does under the hood at the network
layer.
