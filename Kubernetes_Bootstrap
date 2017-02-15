#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ---
# RightScript Name: Kubernetes Bootstrap
# Inputs:
#   RS_CLUSTER_NAME:
#     Category: Cluster
#     Description: Cluster name for the cluster. Must be unique per account.
#     Input Type: single
#     Required: true
#     Advanced: false
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
# ...

# shellcheck source=attachments/rs_cluster.sh
source "$RS_ATTACH_DIR"/rs_cluster.sh

# shellcheck source=attachments/rs_kubernetes.sh
source "$RS_ATTACH_DIR"/rs_kubernetes.sh

# case $(cat ~rightscale/config/RS_BOOT_COUNT) in
# 1)
#   # first boot - prepare server for openshift
#   rs_openshift_config
#   rs_openshift_register
#   rs_openshift_prerequisites
#
#   # reboot needed due to updated kernel
#   sudo reboot
#   ;;
# 2)
#   # second boot - time to join cluster
#   rs_cluster_tag "rs_cluster:status=joining"
#   ;;
# esac
