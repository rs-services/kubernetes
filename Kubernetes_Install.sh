#!/bin/bash
set -eo pipefail
IFS=$'\n\t'

# ---
# RightScript Name: Kubernetes Install
# Inputs:
#   RS_CLUSTER_CLOUD:
#     Category: RightScale
#     Input Type: single
#     Required: true
#     Advanced: true
#   MY_IP:
#     Category: RightScale
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: env:PRIVATE_IP
# Attachments:
# - rs_kubernetes.sh
# - rs_cluster.sh
# ...

# shellcheck source=attachments/rs_cluster.sh
source "$RS_ATTACH_DIR"/rs_cluster.sh

# shellcheck source=attachments/rs_kubernetes.sh
source "$RS_ATTACH_DIR"/rs_kubernetes.sh

# rs_openshift_configure_ansible
# rs_openshift_configure_install
# rs_openshift_run_ansible
# rs_openshift_create_admin_user
# rs_openshift_create_docker_registry
# rs_openshift_monitor_for_new_servers
