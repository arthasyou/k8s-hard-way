#!/bin/bash

set -euo pipefail

readonly dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority="${dir}/../certificates/ca.pem" \
  --embed-certs=true \
  --server=https://192.168.77.40:6443

kubectl config set-credentials admin \
  --client-certificate="${dir}/../certificates/admin.pem" \
  --client-key="${dir}/../certificates/admin-key.pem"

kubectl config set-context kubernetes-the-hard-way \
  --cluster=kubernetes-the-hard-way \
  --user=admin

kubectl config use-context kubernetes-the-hard-way
