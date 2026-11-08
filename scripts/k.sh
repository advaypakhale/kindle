#!/bin/sh
exec ssh -i "${KINDLE_KEY:-$HOME/projects/kindle/kindle_key}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=10 -o ServerAliveInterval=5 -o PubkeyAcceptedAlgorithms=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa root@${KINDLE_HOST:-100.109.187.113} "$@"
