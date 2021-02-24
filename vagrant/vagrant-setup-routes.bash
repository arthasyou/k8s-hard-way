#!/bin/bash

set -euo pipefail

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

case $(hostname) in
worker-0)
  route add -net 10.21.0.0/16 gw 192.168.77.21
  route add -net 10.22.0.0/16 gw 192.168.77.22
  ;;
worker-1)
  route add -net 10.20.0.0/16 gw 192.168.77.20
  route add -net 10.22.0.0/16 gw 192.168.77.22
  ;;
worker-2)
  route add -net 10.20.0.0/16 gw 192.168.77.20
  route add -net 10.21.0.0/16 gw 192.168.77.21
  ;;
*)
  route add -net 10.20.0.0/16 gw 192.168.77.20
  route add -net 10.21.0.0/16 gw 192.168.77.21
  route add -net 10.22.0.0/16 gw 192.168.77.22
  ;;
esac
