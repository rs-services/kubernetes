#!/bin/bash

rs_kube_install_master() {
  # Download kubernetes and docker
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

  apt-get update

  apt-get install -y docker.io
  apt-get install -y kubelet kubeadm kubectl kubernetes-cni

  # Initialize the master
  token=$(kubeadm init --pod-network-cidr 10.244.0.0/16 | tail 1)

  # Save the token as a RightScale credential
  rsc --refreshToken="$RS_REFRESH_TOKEN" --host=us-4.rightscale.com cm15 create credentials \
    credential[name]="KUBE_${RS_CLUSTER_NAME}_CLUSTER_TOKEN" \
    credential[value]="$token"

  # Initialize the overlay network
  kubectl apply -f "$RS_ATTACH_DIR/kube_flannel.yml"
}

rs_kube_install_node() {
  # Download kubernetes and docker
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

  apt-get update

  apt-get install -y docker.io
  apt-get install -y kubelet kubeadm kubectl kubernetes-cni

  # Join cluster
  eval "$KUBE_CLUSTER_JOIN_CMD"
}