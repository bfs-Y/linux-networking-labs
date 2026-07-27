Date: 2026-07-10
Lab: Phase 1 - Container network namespace isolation demonstration

Note: This is a mechanism walkthrough, not a fault investigation. Nothing
was broken; break/07-container-namespace.sh demonstrates namespace
isolation by starting a real container, and fix/07-container-cleanup.sh
tears it down cleanly. No root cause section applies since no fault was
injected.

What was demonstrated:
Starting a Docker container (sudo docker run -d --name test-container
nginx) causes the kernel to create a new network namespace for that
container's process - a private network stack, isolated from the host's
own, with its own interfaces and IP addressing.

Evidence:
$ sudo docker ps | grep test-container
  confirms the container is running.
$ sudo docker inspect test-container | grep -A 5 '"IPAddress"'
  shows the container's private IP, assigned inside its own namespace,
  distinct from the host's addressing.
$ ip a show docker0
  shows the host-side bridge (docker0) that connects the container's
  namespace back to the host's network - the container's veth pair
  attaches here, same underlying mechanism as the bridging/veth work
  done in phase1-layer1-2/bridging/.

Cleanup:
$ sudo docker stop test-container
$ sudo docker rm test-container
$ sudo docker ps -a | grep test-container || echo "Confirmed clean"
  confirms the container and its namespace no longer exist.
$ ip a show docker0
  confirms docker0 returns to an idle state with no containers attached.

Lesson:
Every container has its own network namespace by default - this is the
same underlying kernel primitive (namespaces + veth pairs + a bridge)
used manually in phase1-layer1-2/bridging/, just automated by the
container runtime. Understanding the manual version (bridging/) makes
this automated version transparent rather than "magic."
