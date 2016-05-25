#!/bin/bash -x

SALT_ENGINE=${SALT_ENGINE:-pkg}
SALT_VERSION=${SALT_VERSION:-latest}

RECLASS_ADDRESS=${RECLASS_ADDRESS:-https://github.com/tcpcloud/openstack-salt-model.git}
RECLASS_BRANCH=${RECLASS_BRANCH:-master}
RECLASS_BASE_ENV=${RECLASS_BASE_ENV:-dev}

OS_DISTRIBUTION=${OS_DISTRIBUTION:-ubuntu}
OS_NETWORKING=${OS_NETWORKING:-opencontrail}
OS_DEPLOYMENT=${OS_DEPLOYMENT:-single}

CONFIG_HOSTNAME=${CONFIG_HOSTNAME:-config}
CONFIG_DOMAIN=${CONFIG_DOMAIN:-openstack.local}
CONFIG_HOST=${CONFIG_HOSTNAME}.${CONFIG_DOMAIN}
CONFIG_ADDRESS=${CONFIG_ADDRESS:-10.10.10.200}

FORMULA_SOURCE=${FORMULA_SOURCE:-git}
FORMULA_PATH=${FORMULA_PATH:-/usr/share/salt-formulas/env/_formulas}
FORMULA_BRANCH=${FORMULA_BRANCH:-master}

if [ "$SALT_ENGINE" == "pkg" ]; then
  wget https://raw.githubusercontent.com/atengler/deploy-scripts/master/salt-master-pkg.sh
  source salt-master-pkg.sh
elif [ "$SALT_ENGINE" == "pip" ]; then
  wget https://raw.githubusercontent.com/atengler/deploy-scripts/master/salt-master-pip.sh
  source salt-master-pip.sh
fi

if [ "$FORMULA_SOURCE" == "pkg" ]; then
  wget https://raw.githubusercontent.com/atengler/deploy-scripts/master/salt-formula-pkg.sh
  source salt-formula-pkg.sh
elif [ "$FORMULA_SOURCE" == "git" ]; then
  wget https://raw.githubusercontent.com/atengler/deploy-scripts/master/salt-formula-git.sh
  source salt-formula-git.sh
fi

