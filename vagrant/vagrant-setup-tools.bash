#!/bin/bash

set -euo pipefail

apt-get update
apt-get install -y socat conntrack ipset


