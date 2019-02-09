#!/bin/bash
set -e

kubeadm init --pod-network-cidr=10.244.0.0/16

# By now the master node should be ready!
mkdir -p $HOME/.kube
cp --remove-destination /etc/kubernetes/admin.conf $HOME/.kube/config
chown ${SUDO_UID} $HOME/.kube/config

# Install flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.11.0/Documentation/kube-flannel.yml

# Make master node a running worker node too!
# FIXME: Use taint tolerations instead in the future
kubectl taint nodes --all node-role.kubernetes.io/master-
