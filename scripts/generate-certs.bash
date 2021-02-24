#!/bin/bash

set -euo pipefail

readonly dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

pushd ${dir}/../certificates
trap 'popd' EXIT

# ca
cfssl gencert -initca ${dir}/../json/ca-csr.json | cfssljson -bare ca

# admin
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${dir}/../json/ca-config.json \
  -profile=kubernetes \
  ${dir}/../json/admin-csr.json | cfssljson -bare admin

# worker
for i in {0..2}; do
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=${dir}/../json/ca-config.json \
    -hostname=worker-${i},192.168.77.2${i} \
    -profile=kubernetes \
    ${dir}/../json/worker-${i}-csr.json | cfssljson -bare worker-${i}
done

# kube-controller-manager
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${dir}/../json/ca-config.json \
  -profile=kubernetes \
  ${dir}/../json/kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

#kube-proxy
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${dir}/../json/ca-config.json \
  -profile=kubernetes \
  ${dir}/../json/kube-proxy-csr.json | cfssljson -bare kube-proxy

# kube-scheduler
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${dir}/../json/ca-config.json \
  -profile=kubernetes \
  ${dir}/../json/kube-scheduler-csr.json | cfssljson -bare kube-scheduler

# kubernetes
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${dir}/../json/ca-config.json \
  -hostname=10.32.0.1,192.168.77.40,192.168.77.10,192.168.77.11,192.168.77.12,127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  ${dir}/../json/kubernetes-csr.json | cfssljson -bare kubernetes

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=${dir}/../json/ca-config.json \
  -profile=kubernetes \
  ${dir}/../json/service-account-csr.json | cfssljson -bare service-account

#scp cert to server
for i in {0..2}; do
  scp ca.pem worker-${i}-key.pem worker-${i}.pem vagrant@192.168.77.2${i}:~/
done

for i in {0..2}; do
  scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
  service-account-key.pem service-account.pem vagrant@192.168.77.1${i}:~/
done
