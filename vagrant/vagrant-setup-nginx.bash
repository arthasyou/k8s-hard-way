#!/bin/bash

set -euo pipefail

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y nginx


