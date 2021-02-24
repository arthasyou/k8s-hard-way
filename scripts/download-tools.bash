#!/bin/bash

set -euo pipefail

readonly dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

pushd ${dir}/../tools/
trap 'popd' EXIT

echo "Downloading tools ..."

source "${dir}/versions.bash"

# etcd
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/${etcd_version}/etcd-${etcd_version}-linux-amd64.tar.gz"

tar -xf "etcd-${etcd_version}-linux-amd64.tar.gz"

# Kubernetes
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kubectl" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kube-proxy" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kubelet"

# Other Tools
wget -q --show-progress --https-only --timestamping \
  "https://github.com/kubernetes-sigs/cri-tools/releases/download/${cri_version}/crictl-${cri_version}-linux-amd64.tar.gz" \
  "https://github.com/opencontainers/runc/releases/download/${runc_version}/runc.amd64" \
  "https://github.com/containernetworking/plugins/releases/download/${cni_version}/cni-plugins-linux-amd64-${cni_version}.tgz" \
  "https://github.com/containerd/containerd/releases/download/v${containerd_version}/containerd-${containerd_version}-linux-amd64.tar.gz"

mkdir containerd
mkdir cni
mv runc.amd64 runc
chmod +x runc
tar -xf crictl-${cri_version}-linux-amd64.tar.gz
tar -xf containerd-${containerd_version}-linux-amd64.tar.gz -C containerd
tar -xf cni-plugins-linux-amd64-${cni_version}.tgz -C cni

# curl -sSL \
#   -O "https://github.com/containernetworking/plugins/releases/download/${cni_plugins_version}/cni-plugins-linux-amd64-${cni_plugins_version}.tgz" \
#   -O "https://github.com/opencontainers/runc/releases/download/${runc_version}/runc.amd64" \
#   -O "https://github.com/cri-o/cri-o/releases/download/${crio_version}/crio-${crio_version}.tar.gz" \
#   -O "https://github.com/containers/conmon/releases/download/${conmon_version}/conmon" \
#   -O https://raw.githubusercontent.com/seccomp/containers-golang/master/seccomp.json

# tar -xf "crio-${crio_version}.tar.gz"
# mv "crio-${crio_version}" crio
# mv crio/bin/crio-x86_64-static-glibc crio/bin/crio

# mv runc.amd64 runc

# curl -sSL \
#   -O "https://github.com/containous/traefik/releases/download/${traefik_version}/traefik_linux-amd64"

# mv traefik_linux-amd64 traefik

chmod +x \
  kube-apiserver \
  kube-controller-manager \
  kube-scheduler \
  kube-proxy \
  kubelet \
  kubectl 
  # runc \
  # traefik \
  # conmon
