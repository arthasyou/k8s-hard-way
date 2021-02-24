#!/bin/bash

set -euo pipefail

readonly dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pushd "${dir}/../"
trap 'popd' EXIT

# cat <<EOF | kubectl apply -f -
# apiVersion: rbac.authorization.k8s.io/v1beta1
# kind: ClusterRole
# metadata:
#   annotations:
#     rbac.authorization.kubernetes.io/autoupdate: "true"
#   labels:
#     kubernetes.io/bootstrapping: rbac-defaults
#   name: system:kube-apiserver-to-kubelet
# rules:
#   - apiGroups:
#       - ""
#     resources:
#       - nodes/proxy
#       - nodes/stats
#       - nodes/log
#       - nodes/spec
#       - nodes/metrics
#     verbs:
#       - "*"
# EOF

# cat <<EOF | kubectl apply --kubeconfig ${dir}/../config/admin.kubeconfig -f -
# apiVersion: rbac.authorization.k8s.io/v1beta1
# kind: ClusterRoleBinding
# metadata:
#   name: system:kube-apiserver
#   namespace: ""
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: system:kube-apiserver-to-kubelet
# subjects:
#   - apiGroup: rbac.authorization.k8s.io
#     kind: User
#     name: kubernetes
# EOF

kubectl apply -f ${dir}/../yaml/kube-apiserver-to-kubelet.yaml
kubectl apply -f ${dir}/../yaml/bind-kube-apiserver-to-kubelet.yaml
