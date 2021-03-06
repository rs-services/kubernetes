#!/bin/bash

install_script() {
  cp "$RS_ATTACH_DIR/$1.sh" /tmp
  mkdir -p ~/scripts
  cp /tmp/$1.sh ~/scripts
  chmod +x ~/scripts/$1.sh
  rm /tmp/$1.sh
}

install_task() {
  install_script "$1"
  sudo cp "$RS_ATTACH_DIR/$1.cron" /etc/cron.d
}

rs_cluster_tag() {
  while true; do
    rsc --rl10 cm15 multi_add /api/tags/multi_add "resource_hrefs[]=$RS_SELF_HREF" "tags[]=$1"

    tag=$(rsc --rl10 --xm ".name:val(\"$1\")" cm15 by_resource /api/tags/by_resource "resource_hrefs[]=$RS_SELF_HREF")

    if [[ "$tag" = "" ]]; then
      sleep 1
    else
      break
    fi
 done
}

rs_cluster_config() {
  echo "Setting cluster configuration..."
  mkdir -p ~/config
  echo $RS_CLUSTER_NAME > ~/config/RS_CLUSTER_NAME

  if [[ -f ~/config/RS_BOOT_COUNT ]]; then
    boot_count=$(cat ~/config/RS_BOOT_COUNT)
    boot_count=$((boot_count+1))
  else
    boot_count=1
  fi

  echo $boot_count > ~/config/RS_BOOT_COUNT
}

rs_cluster_scripts() {
  echo "Installing cluster scripts..."
  install_task "authorize_cluster_keys"
}

rs_cluster_ssh_key() {
  if [[ ! -f ~/.ssh/id_rsa ]]; then
    echo "Creating ssh key for rightlink user..."
    ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa
  fi
}
