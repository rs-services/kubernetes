#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ---
# RightScript Name: Kubernetes Master
# Inputs:
#   RS_CLUSTER_NAME:
#     Category: Cluster
#     Description: Cluster name for the cluster. Must be unique per account.
#     Input Type: single
#     Required: true
#     Advanced: false
#   RS_REFRESH_TOKEN:
#     Category: Cluster
#     Description: Refresh token used to call the RightScale API
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: cred:RS_REFRESH_TOKEN
#   RS_CLUSTER_ROLE:
#     Category: Cluster
#     Input Type: single
#     Required: true
#     Advanced: false
#     Possible Values:
#     - text:master
#     - text:node
#   MY_IP:
#     Category: RightScale
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: env:PRIVATE_IP
# Attachments:
# - rs_cluster.sh
# - rs_kubernetes.sh
# - kube_flannel.yml
# - kube_dashboard.yml
# ...

# shellcheck source=attachments/rs_cluster.sh
source "$RS_ATTACH_DIR"/rs_cluster.sh

# shellcheck source=attachments/rs_kubernetes.sh
source "$RS_ATTACH_DIR"/rs_kubernetes.sh

rs_kube_install_master
