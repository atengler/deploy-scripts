#!/bin/bash

SALT_VERSION=${SALT_VERSION:-latest}

CONFIG_HOSTNAME=${CONFIG_HOSTNAME:-config}
CONFIG_DOMAIN=${CONFIG_DOMAIN:-openstack.local}
CONFIG_HOST=${CONFIG_HOSTNAME}.${CONFIG_DOMAIN}

echo -e "\nPreparing base OS repository ...\n"

echo -e "deb [arch=amd64] http://apt.tcpcloud.eu/nightly/ trusty main security extra tcp" > /etc/apt/sources.list
wget -O - http://apt.tcpcloud.eu/public.gpg | apt-key add -

apt-get clean
apt-get update

echo -e "\nInstalling salt minion ...\n"

if [ "$SALT_VERSION" == "latest" ]; then
  apt-get install -y salt-common salt-minion
else
  apt-get install -y --force-yes salt-common=$SALT_VERSION salt-minion=$SALT_VERSION
fi

[ ! -d /etc/salt/minion.d ] && mkdir -p /etc/salt/minion.d

echo -e "master: 127.0.0.1\nid: $CONFIG_HOST" > /etc/salt/minion.d/minion.conf

