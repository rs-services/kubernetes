#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# gather cluster data
cluster_name=$(cat ~rightscale/config/RS_CLUSTER_NAME)
key_tag_prefix="rs_cluster:ssh_key="
ip_tag_prefix="rs_cluster:ip="

/usr/local/bin/rsc --rl10 cm15 by_tag \
  tags/by_tag resource_type=instances \
  tags[]="rs_cluster:name=$cluster_name" \
  include_tags_with_prefix="rs_cluster:" \
  > ~rightscale/config/cluster_machines.json

# ensure .ssh directores exist
if [[ ! -d ~rightscale/.ssh ]]; then
  mkdir ~rightscale/.ssh
  chown rightscale:rightscale ~rightscale/.ssh
  chmod 755 ~rightscale/.ssh
fi

if [[ ! -d /root/.ssh ]]; then
  mkdir /root/.ssh
  chown root:root /root/.ssh
  chmod 755 /root/.ssh
fi

# process authorized_keys file
declare -a "KEY_TAGS=($(/usr/local/bin/rsc \
  --xm 'string:contains("'$key_tag_prefix'")' json \
  < ~rightscale/config/cluster_machines.json))"

if [[ ! -f ~rightscale/.ssh/authorized_keys ]]; then
  touch ~rightscale/.ssh/authorized_keys
  chown rightscale:rightscale ~rightscale/.ssh/authorized_keys
  chmod 644 ~rightscale/.ssh/authorized_keys
fi

cp ~rightscale/.ssh/authorized_keys /tmp
chown rightscale:rightscale /tmp/authorized_keys

for key_tag in "${KEY_TAGS[@]}"; do
  if ! grep "${key_tag:${#key_tag_prefix}}" /tmp/authorized_keys > /dev/null; then
    echo "${key_tag:${#key_tag_prefix}}" >> /tmp/authorized_keys
  fi
done

mv /tmp/authorized_keys ~rightscale/.ssh/authorized_keys

# process known_hosts file
declare -a "IP_TAGS=($(/usr/local/bin/rsc \
  --xm 'string:contains("'$ip_tag_prefix'")' json \
  < ~rightscale/config/cluster_machines.json))"

if [[ ! -f ~rightscale/.ssh/known_hosts ]]; then
  touch ~rightscale/.ssh/known_hosts
  chown rightscale:rightscale ~rightscale/.ssh/known_hosts
  chmod 644 ~rightscale/.ssh/known_hosts
fi

cp ~rightscale/.ssh/known_hosts /tmp
chown rightscale:rightscale /tmp/known_hosts

for ip_tag in "${IP_TAGS[@]}"; do
  if ! grep "${ip_tag:${#ip_tag_prefix}}" /tmp/known_hosts > /dev/null; then
    ssh-keyscan "${ip_tag:${#ip_tag_prefix}}" 2>/dev/null | tee -a /tmp/known_hosts > /dev/null
  fi
done

mv /tmp/known_hosts ~rightscale/.ssh/known_hosts

# root should share ssh identity (needed for ansible)
cp -R ~rightscale/.ssh/* /root/.ssh/
