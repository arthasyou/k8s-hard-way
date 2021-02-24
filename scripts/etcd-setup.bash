#!/bin/bash

set -euo pipefail

readonly dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

source "${dir}/versions.bash"

pushd ${dir}/../tools
trap 'popd' EXIT

HOST_NAME="controller-"
INTERNAL_IP="192.168.77.1"

for i in {0..2}; do
# span etcd.service file 
cat <<EOF | tee ${dir}/../services/${HOST_NAME}${i}-etcd.service
    [Unit]
    Description=etcd
    Documentation=https://github.com/coreos

    [Service]
    Type=notify
    ExecStart=/usr/local/bin/etcd \\
    --name ${HOST_NAME}${i} \\
    --cert-file=/etc/etcd/kubernetes.pem \\
    --key-file=/etc/etcd/kubernetes-key.pem \\
    --peer-cert-file=/etc/etcd/kubernetes.pem \\
    --peer-key-file=/etc/etcd/kubernetes-key.pem \\
    --trusted-ca-file=/etc/etcd/ca.pem \\
    --peer-trusted-ca-file=/etc/etcd/ca.pem \\
    --peer-client-cert-auth \\
    --client-cert-auth \\
    --initial-advertise-peer-urls https://${INTERNAL_IP}${i}:2380 \\
    --listen-peer-urls https://${INTERNAL_IP}${i}:2380 \\
    --listen-client-urls https://${INTERNAL_IP}${i}:2379,https://127.0.0.1:2379 \\
    --advertise-client-urls https://${INTERNAL_IP}${i}:2379 \\
    --initial-cluster-token etcd-cluster-0 \\
    --initial-cluster ${HOST_NAME}0=https://${INTERNAL_IP}0:2380,${HOST_NAME}1=https://${INTERNAL_IP}1:2380,${HOST_NAME}2=https://${INTERNAL_IP}2:2380 \\
    --initial-cluster-state new \\
    --data-dir=/var/lib/etcd
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
EOF
# scp
scp etcd-${etcd_version}-linux-amd64/etcd* root@${INTERNAL_IP}${i}:/usr/local/bin
scp ${dir}/../services/${HOST_NAME}${i}-etcd.service root@${INTERNAL_IP}${i}:/etc/systemd/system/etcd.service
cat <<EOF | vagrant ssh ${HOST_NAME}${i} -- sudo bash
    sudo mkdir -p /etc/etcd /var/lib/etcd
    sudo chmod 700 /var/lib/etcd    
    sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
    sudo systemctl daemon-reload
    sudo systemctl enable etcd    
EOF
done

# ssh to each controller server run sudo systemctl start etcd
# for i in {0..2}; do
#     ssh root@${INTERNAL_IP}${i} "systemctl start etcd"
# done








