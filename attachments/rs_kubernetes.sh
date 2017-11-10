#!/bin/bash

rs_kube_install_master() {
  # Download kubernetes and docker
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

  sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

  sudo apt-get update

  sudo apt-get install -y docker.io
  sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

  # Initialize the master and grab the join command to be used by the cluster nodes
  token=$(sudo kubeadm init --pod-network-cidr 10.244.0.0/16 | grep -i "kubeadm join")
  
  RS_API_ENDPOINT=$(echo $RS_SERVER | cut -d '\' -f3)

  # Save the token as a RightScale credential
  rsc --refreshToken="$RS_REFRESH_TOKEN" --host="$RS_API_ENDPOINT" cm15 create credentials \
    credential[name]="KUBE_${RS_CLUSTER_NAME}_CLUSTER_TOKEN" \
    credential[value]="$token"
    
  # When you run the kubeadm init command along with the join command that is grabbed above,
  # it provides these instructions for steps that need to be taken before subsequent commands will work:
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Initialize the overlay network
  echo ">>> flannel set up"
  sudo kubectl apply -f "$RS_ATTACH_DIR/kube_flannel.yml"
    
  echo ">>> dashboard set up"
  sudo kubectl apply -f "$RS_ATTACH_DIR/kube_dashboard.yml"
  
  echo ">>> influxdb set up"
  sudo kubectl apply -f "$RS_ATTACH_DIR/kube_influxdb.yml"
  
  echo ">>> Exposing dashboard"
  sudo kubectl -n kube-system expose deployment kubernetes-dashboard \
        --name kubernetes-dashboard-nodeport --type=NodePort
        
  ### This is is NOT for PRODUCTION
  ### This gives full access to the Kubernetes cluster.
  echo ">>> Creating open access to dashboard with full ADMIN level permissions."
  kubectl create -f "$RS_ATTACH_DIR/kube_dashboard_admin.yml"

  echo ">>> get dashboard port"
  dashboard_port=$(sudo kubectl -n kube-system get svc/kubernetes-dashboard-nodeport | grep 'kubernetes-dashboard' | sed 's/  */%/g' | cut -d "%" -f5 | cut -d":" -f2 | cut -d"/" -f1)

  rs_cluster_tag "rs_cluster:dashboard_port=$dashboard_port"
}

rs_kube_install_node() {
  # Download kubernetes and docker
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

  sudo apt-get update

  sudo apt-get install -y docker.io
  sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

  # Join cluster
  echo ">>> Join cluster"
  eval "sudo $KUBE_CLUSTER_JOIN_CMD"
}
