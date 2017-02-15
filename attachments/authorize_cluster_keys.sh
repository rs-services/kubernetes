#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# gather cluster data
cluster_name=$(cat ~/config/RS_CLUSTER_NAME)
key_tag_prefix="rs_cluster:ssh_key="
ip_tag_prefix="rs_cluster:ip="

/usr/local/bin/rsc --rl10 cm15 by_tag \
  tags/by_tag resource_type=instances \
  tags[]="rs_cluster:name=$cluster_name" \
  include_tags_with_prefix="rs_cluster:" \
  > ~/config/cluster_machines.json

# ensure .ssh directores exist
if [[ ! -d ~/.ssh ]]; then
  mkdir ~/.ssh
  chown rightlink: ~/.ssh
  chmod 755 ~/.ssh
fi

if [[ ! -d /root/.ssh ]]; then
  mkdir /root/.ssh
  chown root:root /root/.ssh
  chmod 755 /root/.ssh
fi

# process authorized_keys file
declare -a "KEY_TAGS=($(/usr/local/bin/rsc \
  --xm 'string:contains("'$key_tag_prefix'")' json \
  < ~/config/cluster_machines.json))"

if [[ ! -f ~/.ssh/authorized_keys ]]; then
  touch ~/.ssh/authorized_keys
  chown rightlink: ~/.ssh/authorized_keys
  chmod 644 ~/.ssh/authorized_keys
fi

cp ~/.ssh/authorized_keys /tmp
chown rightlink: /tmp/authorized_keys

for key_tag in "${KEY_TAGS[@]}"; do
  if ! grep "${key_tag:${#key_tag_prefix}}" /tmp/authorized_keys > /dev/null; then
    echo "${key_tag:${#key_tag_prefix}}" >> /tmp/authorized_keys
  fi
done

mv /tmp/authorized_keys ~/.ssh/authorized_keys

# process known_hosts file
declare -a "IP_TAGS=($(/usr/local/bin/rsc \
  --xm 'string:contains("'$ip_tag_prefix'")' json \
  < ~/config/cluster_machines.json))"

if [[ ! -f ~/.ssh/known_hosts ]]; then
  touch ~/.ssh/known_hosts
  chown rightlink: ~/.ssh/known_hosts
  chmod 644 ~/.ssh/known_hosts
fi

cp ~/.ssh/known_hosts /tmp
chown rightlink: /tmp/known_hosts

for ip_tag in "${IP_TAGS[@]}"; do
  if ! grep "${ip_tag:${#ip_tag_prefix}}" /tmp/known_hosts > /dev/null; then
    ssh-keyscan "${ip_tag:${#ip_tag_prefix}}" 2>/dev/null | tee -a /tmp/known_hosts > /dev/null
  fi
done

mv /tmp/known_hosts ~/.ssh/known_hosts

# root should share ssh identity (needed for ansible)
cp -R ~/.ssh/* /root/.ssh/
