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

if [ -x "`which invoke-rc.d 2>/dev/null`" -a -x "/etc/init.d/salt-minion" ] ; then
  apt-get purge -y salt-minion salt-common && apt-get autoremove -y
fi

apt-get install -y python-pip python-dev zlib1g-dev reclass git

if [ "$SALT_VERSION" == "latest" ]; then
  pip install salt
else
  pip install salt==$SALT_VERSION
fi

wget -O /etc/init.d/salt-minion https://anonscm.debian.org/cgit/pkg-salt/salt.git/plain/debian/salt-minion.init && chmod 755 /etc/init.d/salt-minion
ln -s /usr/local/bin/salt-minion /usr/bin/salt-minion

[ ! -d /etc/salt/minion.d ] && mkdir -p /etc/salt/minion.d

echo -e "master: 127.0.0.1\nid: $CONFIG_HOST" > /etc/salt/minion.d/minion.conf

