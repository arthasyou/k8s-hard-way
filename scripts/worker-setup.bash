#!/bin/bash

set -euo pipefail

readonly dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

source "${dir}/versions.bash"

pushd ${dir}/../tools
trap 'popd' EXIT

HOST_NAME="worker-"
INTERNAL_IP="192.168.77.2"
POD_CIDR="10.22.0.0/16"

# span cni conf
cat <<EOF | tee ${dir}/../others/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

cat <<EOF | tee ${dir}/../others/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "name": "lo",
    "type": "loopback"
}
EOF

cat << EOF | tee ${dir}/../others/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF

cat <<EOF | tee ${dir}/../services/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Kubelet-config.yaml
for i in {0..2}; do
cat <<EOF | tee ${dir}/../yaml/${HOST_NAME}${i}-kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOST_NAME}${i}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOST_NAME}${i}-key.pem"
EOF
done

# kubelet.service
cat <<EOF | tee ${dir}/../services/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# kube-proxy-config.yaml
cat <<EOF | tee ${dir}/../yaml/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF

# kube-proxy.service
cat <<EOF | tee ${dir}/../services/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

for i in {0..2}; do
# scp
scp crictl kubectl kube-proxy kubelet runc root@${INTERNAL_IP}${i}:/usr/local/bin
scp -r containerd vagrant@${INTERNAL_IP}${i}:~/
scp -r cni vagrant@${INTERNAL_IP}${i}:~/
scp ${dir}/../others/10-bridge.conf vagrant@${INTERNAL_IP}${i}:~/
scp ${dir}/../others/99-loopback.conf vagrant@${INTERNAL_IP}${i}:~/
scp ${dir}/../others/config.toml vagrant@${INTERNAL_IP}${i}:~/
scp ${dir}/../services/containerd.service root@${INTERNAL_IP}${i}:/etc/systemd/system/containerd.service
scp ${dir}/../yaml/${HOST_NAME}${i}-kubelet-config.yaml vagrant@${INTERNAL_IP}${i}:~/
scp ${dir}/../services/kubelet.service root@${INTERNAL_IP}${i}:/etc/systemd/system/kubelet.service
scp ${dir}/../yaml/kube-proxy-config.yaml vagrant@${INTERNAL_IP}${i}:~/
scp ${dir}/../services/kube-proxy.service root@${INTERNAL_IP}${i}:/etc/systemd/system/kube-proxy.service
scp ${dir}/../config/${HOST_NAME}${i}.kubeconfig vagrant@${INTERNAL_IP}${i}:~/
scp ${dir}/../config/kube-proxy.kubeconfig vagrant@${INTERNAL_IP}${i}:~/

cat <<EOF | vagrant ssh ${HOST_NAME}${i} -- sudo bash
    sudo mkdir -p \
      /etc/cni/net.d \
      /opt/cni/bin \
      /var/lib/kubelet \
      /var/lib/kube-proxy \
      /var/lib/kubernetes \
      /var/run/kubernetes
    
    sudo mv cni/* /opt/cni/bin
    sudo mv containerd/bin/* /bin/
    sudo mv 10-bridge.conf /etc/cni/net.d/10-bridge.conf
    sudo mv 99-loopback.conf /etc/cni/net.d/99-loopback.conf
    sudo mkdir -p /etc/containerd/
    sudo mv config.toml /etc/containerd/config.toml

    sudo mv ${HOST_NAME}${i}-key.pem ${HOST_NAME}${i}.pem /var/lib/kubelet/
    sudo mv ${HOST_NAME}${i}.kubeconfig /var/lib/kubelet/kubeconfig
    sudo mv ca.pem /var/lib/kubernetes/
    sudo mv ${HOST_NAME}${i}-kubelet-config.yaml /var/lib/kubelet/kubelet-config.yaml
    sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
    sudo mv kube-proxy-config.yaml /var/lib/kube-proxy/kube-proxy-config.yaml

    sudo systemctl daemon-reload
    sudo systemctl enable containerd kubelet kube-proxy
    sudo systemctl start containerd kubelet kube-proxy
    rm -rf containerd cni
EOF
done