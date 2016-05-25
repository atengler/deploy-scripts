#!/bin/bash

SALT_ENGINE=${SALT_ENGINE:-pkg}
SALT_VERSION=${SALT_VERSION:-latest}

RECLASS_ADDRESS=${RECLASS_ADDRESS:-https://github.com/tcpcloud/openstack-salt-model.git}
RECLASS_BRANCH=${RECLASS_BRANCH:-master}
RECLASS_BASE_ENV=${RECLASS_BASE_ENV:-dev}

OS_DISTRIBUTION=${OS_DISTRIBUTION:-ubuntu}
OS_VERSION=${OS_VERSION:-liberty}
OS_DEPLOYMENT=${OS_DEPLOYMENT:-single}

FORMULA_SOURCE=${FORMULA_SOURCE:-git}

echo -e "\nPreparing base OS repository ...\n"

echo -e "deb [arch=amd64] http://apt.tcpcloud.eu/nightly/ trusty main security extra tcp tcp-salt" > /etc/apt/sources.list
wget -O - http://apt.tcpcloud.eu/public.gpg | apt-key add -

apt-get clean
apt-get update

echo -e "\nInstalling salt master ...\n"

if [ -x "`which invoke-rc.d 2>/dev/null`" -a -x "/etc/init.d/salt-minion" ] ; then
  apt-get purge -y salt-minion salt-common && apt-get autoremove -y
fi

apt-get install -y python-pip python-dev zlib1g-dev reclass git

if [ "$SALT_VERSION" == "latest" ]; then
  pip install salt
else
  pip install salt==$SALT_VERSION
fi

wget -O /etc/init.d/salt-master https://anonscm.debian.org/cgit/pkg-salt/salt.git/plain/debian/salt-master.init && chmod 755 /etc/init.d/salt-master
ln -s /usr/local/bin/salt-master /usr/bin/salt-master

[ ! -d /etc/salt/master.d ] && mkdir -p /etc/salt/master.d

cat << 'EOF' > /etc/salt/master.d/master.conf
file_roots:
  base:
  - /usr/share/salt-formulas/env
pillar_opts: False
open_mode: True
reclass: &reclass
  storage_type: yaml_fs
  inventory_base_uri: /srv/salt/reclass
ext_pillar:
  - reclass: *reclass
master_tops:
  reclass: *reclass
EOF

echo "Configuring reclass ..."

[ ! -d /etc/reclass ] && mkdir /etc/reclass
cat << 'EOF' > /etc/reclass/reclass-config.yml
storage_type: yaml_fs
pretty_print: True
output: yaml
inventory_base_uri: /srv/salt/reclass
EOF

git clone ${RECLASS_ADDRESS} /srv/salt/reclass -b ${RECLASS_BRANCH}

cat << EOF > /srv/salt/reclass/nodes/config.openstack.local
classes:
- service.git.client
- system.linux.system.single
- system.openssh.client.workshop
- system.salt.master.single
- system.salt.master.formula.$FORMULA_SOURCE
- system.reclass.storage.salt
- system.reclass.storage.system.${OS_DISTRIBUTION}_${OS_VERSION}_${OS_DEPLOYMENT}
parameters:
  _param:
    reclass_data_repository: "$RECLASS_ADDRESS"
    reclass_data_revision: $RECLASS_BRANCH
    salt_formula_branch: $FORMULA_BRANCH
    reclass_config_master: 10.10.10.200
    single_address: 10.10.10.200
    salt_master_host: 127.0.0.1
    salt_master_base_environment: $RECLASS_BASE_ENV
  linux:
    system:
      name: config
      domain: openstack.local
EOF

if [ "$SALT_VERSION" == "latest" ]; then
cat << EOF >> /srv/salt/reclass/nodes/config.openstack.local
  salt:
    master:
      accept_policy: open_mode
      source:
        engine: $SALT_ENGINE
    minion:
      source:
        engine: $SALT_ENGINE
EOF
else
cat << EOF >> /srv/salt/reclass/nodes/config.openstack.local
  salt:
    master:
      accept_policy: open_mode
      source:
        engine: $SALT_ENGINE
        version: $SALT_VERSION
    minion:
      source:
        engine: $SALT_ENGINE
        version: $SALT_VERSION
EOF
fi

