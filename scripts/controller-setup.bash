#!/bin/bash

set -euo pipefail

readonly dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

source "${dir}/versions.bash"

pushd ${dir}/../tools
trap 'popd' EXIT

HOST_NAME="controller-"
INTERNAL_IP="192.168.77.1"

for i in {0..2}; do
# span kube-apiserver.service file 
cat <<EOF | tee ${dir}/../services/${HOST_NAME}${i}-kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP}${i} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://${INTERNAL_IP}0:2379,https://${INTERNAL_IP}1:2379,https://${INTERNAL_IP}2:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
done

# span kube-controller-manager.service file
cat <<EOF | tee ${dir}/../services/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# kube-scheduler.yaml
cat <<EOF | tee ${dir}/../yaml/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

# kube-scheduler.service
cat <<EOF | tee ${dir}/../services/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# health profile
cat <<EOF | tee ${dir}/../others/kubernetes.default.svc.cluster.local
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

for i in {0..2}; do
# scp
scp kube-apiserver kube-controller-manager kube-scheduler kubectl root@${INTERNAL_IP}${i}:/usr/local/bin
scp ${dir}/../services/${HOST_NAME}${i}-kube-apiserver.service root@${INTERNAL_IP}${i}:/etc/systemd/system/kube-apiserver.service
scp ${dir}/../services/kube-controller-manager.service root@${INTERNAL_IP}${i}:/etc/systemd/system/kube-controller-manager.service
scp ${dir}/../services/kube-scheduler.service root@${INTERNAL_IP}${i}:/etc/systemd/system/kube-scheduler.service
scp ${dir}/../yaml/kube-scheduler.yaml vagrant@${INTERNAL_IP}${i}:~/
scp ${dir}/../others/kubernetes.default.svc.cluster.local vagrant@${INTERNAL_IP}${i}:~/

cat <<EOF | vagrant ssh ${HOST_NAME}${i} -- sudo bash
    sudo mkdir -p /etc/kubernetes/config
    sudo mkdir -p /var/lib/kubernetes/
    sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
        service-account-key.pem service-account.pem \
        encryption-config.yaml /var/lib/kubernetes/
    sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
    sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
    sudo mv ~/kube-scheduler.yaml /etc/kubernetes/config/kube-scheduler.yaml
    sudo systemctl daemon-reload
    sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
    sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
    sudo mv kubernetes.default.svc.cluster.local /etc/nginx/sites-available/kubernetes.default.svc.cluster.local
    sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    sudo systemctl enable nginx
EOF
done