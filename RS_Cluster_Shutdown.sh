#! /bin/bash

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

# Determine location of rsc
[[ -e /usr/local/bin/rsc ]] && rsc=/usr/local/bin/rsc || rsc=/opt/bin/rsc

echo "Deleting Kubernetes token credential ..."

rs_decom_reason="$($rsc --retry=5 --timeout=10 rl10 show /rll/proc/shutdown_kind)"
os_decom_reason=service_restart # Our default
if [[ `systemctl 2>/dev/null` =~ -\.mount ]] || [[ "$(readlink /sbin/init)" =~ systemd ]]; then
  # Systemd doesn't use runlevels, so we can't rely on that
  jobs="$(systemctl list-jobs)"
  echo "$jobs" | egrep -q 'reboot.target.*start'   && os_decom_reason=reboot
  echo "$jobs" | egrep -q 'halt.target.*start'     && os_decom_reason=shutdown
  echo "$jobs" | egrep -q 'poweroff.target.*start' && os_decom_reason=shutdown
else
  # upstart, sysvinit, or unknown system. The current runlevel should tell us what's up
  [[ `runlevel | cut -d ' ' -f 2` == "6" ]]   && os_decom_reason=reboot
  [[ `runlevel | cut -d ' ' -f 2` =~ 0|1|S ]] && os_decom_reason=shutdown
fi

case "$os_decom_reason" in
  reboot|service_restart)
    decom_reason=$os_decom_reason
    ;;
  
  shutdown)
    if [[ "$rs_decom_reason" == "terminate" ]]; then
      decom_reason=terminate

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

    else
      decom_reason=stop
    fi
    ;;
esac
