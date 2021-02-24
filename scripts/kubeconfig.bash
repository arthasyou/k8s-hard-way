#!/bin/bash

set -euo pipefail

readonly dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

LOADBALANCER_ADDRESS=192.168.77.40
LOCAL_ADDRESS=127.0.0.1

pushd ${dir}/../config
trap 'popd' EXIT

# worker
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=${dir}/../certificates/ca.pem \
    --embed-certs=true \
    --server=https://${LOADBALANCER_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${dir}/../certificates/${instance}.pem \
    --client-key=${dir}/../certificates/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

# kube-proxy
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=${dir}/../certificates/ca.pem \
  --embed-certs=true \
  --server=https://${LOADBALANCER_ADDRESS}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=${dir}/../certificates/kube-proxy.pem \
  --client-key=${dir}/../certificates/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

#kube-controller-manager
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=${dir}/../certificates/ca.pem \
  --embed-certs=true \
  --server=https://${LOCAL_ADDRESS}:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=${dir}/../certificates/kube-controller-manager.pem \
  --client-key=${dir}/../certificates/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

# kube-scheduler
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=${dir}/../certificates/ca.pem \
    --embed-certs=true \
    --server=https://${LOCAL_ADDRESS}:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=${dir}/../certificates/kube-scheduler.pem \
    --client-key=${dir}/../certificates/kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

# admin
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=${dir}/../certificates/ca.pem \
    --embed-certs=true \
    --server=https://${LOCAL_ADDRESS}:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=${dir}/../certificates/admin.pem \
    --client-key=${dir}/../certificates/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig

#scp config to server
for i in {0..2}; do
  scp worker-${i}.kubeconfig kube-proxy.kubeconfig vagrant@192.168.77.2${i}:~/
done

for i in {0..2}; do
  scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig \
  vagrant@192.168.77.1${i}:~/
done