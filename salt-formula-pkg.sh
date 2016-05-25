#!/bin/bash

CONFIG_HOST=${CONFIG_HOST:-config.openstack.local}

FORMULA_PATH=${FORMULA_PATH:-/usr/share/salt-formulas}

echo "Configuring necessary formulas ..."
which wget > /dev/null || (apt-get update; apt-get install -y wget)

echo "deb [arch=amd64] http://apt.tcpcloud.eu/nightly/ trusty main security extra tcp tcp-salt" > /etc/apt/sources.list
wget -O - http://apt.tcpcloud.eu/public.gpg | apt-key add -

apt-get clean
apt-get update

declare -a FORMULA_SERVICES=("linux" "reclass" "salt" "openssh" "ntp" "git" "nginx" "collectd" "sensu" "heka" "sphinx")

for FORMULA_SERVICE in "${FORMULA_SERVICES[@]}"; do
    echo -e "\nConfiguring salt formula ${FORMULA_SERVICE} ...\n"
    [ ! -d "${FORMULA_PATH}/env/${FORMULA_SERVICE}" ] && \
        apt-get install -y salt-formula-${FORMULA_SERVICE}
done

echo -e "\nRestarting services ...\n"
service salt-master restart
[ ! -f /srv/salt/env ] && rm -f /etc/salt/pki/minion/minion_master.pub
service salt-minion restart
salt-call pillar.data > /dev/null 2>&1

echo -e "\nReclass metadata ...\n"
reclass --nodeinfo ${CONFIG_HOST}

echo -e "\nSalt grains metadata ...\n"
salt-call grains.items --no-color

echo -e "\nSalt pillar metadata ...\n"
salt-call pillar.data --no-color

echo -e "\nRunning necessary base states ...\n"
salt-call state.sls linux,openssh,salt.minion,salt.master.service --no-color

echo -e "\nRunning complete state ...\n"
salt-call state.highstate --no-color

