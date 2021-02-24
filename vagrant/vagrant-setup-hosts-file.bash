#!/bin/bash

set -euo pipefail

cat <<EOF | sudo tee -a /etc/hosts

# KTHW Vagrant machines
192.168.77.10 controller-0
192.168.77.11 controller-1
192.168.77.12 controller-2
192.168.77.20 worker-0
192.168.77.21 worker-1
192.168.77.22 worker-2
EOF

# This is added to get around the DNS issue in Ubuntu
# See https://github.com/kubernetes/kubernetes/issues/66067
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
