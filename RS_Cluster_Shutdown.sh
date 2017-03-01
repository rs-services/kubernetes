#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ---
# RightScript Name: Cluster Shutdown
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
# ...

[[ $DECOM_REASON != "terminate" ]] && echo "Server is not terminating. Skipping." && exit 0

echo "Deleting cluster token ..."

# If this host is a cluster master then delete the cluster token credential at shutdown.
# Note this will only work if we have one master like we do now since the search
# below would return multiple results on a multi-master setup.
instance=$(rsc --rl10 --x1 ':has(.rel:val("self")).href' cm15 index_instance_session /api/sessions/instance)
master=$(rsc --rl10 cm15 by_tag /api/tags/by_tag "tags[]=rs_cluster:role=master" resource_type=instances --x1 .links.href)

if [ $instance == $master ]; then

  # Find token credential url
  token_url=$(rsc --refreshToken="${RS_REFRESH_TOKEN}" --host=us-4.rightscale.com \
    cm15 index /api/credentials filter[]=name=="KUBE_${RS_CLUSTER_NAME}_CLUSTER_TOKEN" \
    --x1 ':has(.rel:val("self")).href')

  # Delete token
  rsc --refreshToken="${RS_REFRESH_TOKEN}" --host=us-4.rightscale.com cm15 destroy $token_url
fi
