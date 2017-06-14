#!/bin/bash
set -e

source data/config.bash
source data/secrets.bash

echo "After this is done, you need to manually edit /etc/kubernetes/manifests/kube-apiserver.yaml"
echo "Adding --bind-address=${KUBE_MASTER_IP} to the command of the container, right below --advertise-address"
echo "Alsos change the host of the health chck to ${KUBE_MASTER_IP} from 127.0.0.1"
echo "Should be fixed by https://github.com/kubernetes/kubeadm/issues/305"

kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="${KUBE_MASTER_IP}" --token="${KUBEADM_TOKEN}"

# By now the master node should be ready!

# Install flannel
kubectl apply -f kube-flannel-rbac.yaml
kubectl apply -f kube-flannel.yaml

# Make master node a running worker node too!
# FIXME: Use taint tolerations instead in the future
kubectl taint nodes --all node-role.kubernetes.io/master-