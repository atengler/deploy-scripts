#!/bin/bash

# Variables
export GRAFANA_REPO="github.com/atengler/grafana"

# Setup install dependencies
echo "Checking installation dependencies ..."

apt-get -qq update || (echo "Package meta update failed, check your internet connection" && exit 1)
git --version > /dev/null 2>&1 || apt-get install git -y
wget --version > /dev/null 2>&1 || apt-get install wget -y
npm --version > /dev/null 2>&1 || apt-get install npm -y
if ! $(node --version > /dev/null 2>&1); then
     nodejs --version > /dev/null 2>&1 || apt-get install nodejs -y
     ln -s /usr/bin/nodejs /usr/bin/node
fi

# Setup Go
echo "Checking Go installation ..."

export GOROOT=/usr/local/go
export GOPATH=/srv/grafana
echo $PATH | grep "grafana" > /dev/null || export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

if ! $(go version | grep "1.7" > /dev/null); then
    mkdir /tmp/go-inst
    cd /tmp/go-inst
    wget https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz
    tar -xf go1.7.linux-amd64.tar.gz
    mv go /usr/local
    rm -rf /tmp/go-inst
    go version | grep "1.7" > /dev/null 2>&1 || (echo "Go setup failed" && exit 1)
fi

# Install Grafana from source
echo "Installing Grafana from source ..."

if [ ! -d $GOPATH ]; then
    mkdir -p $GOPATH
    cd $GOPATH

    go get $GRAFANA_REPO

    # Setup for forked Grafana repo
    if [ $GRAFANA_REPO != "github.com/grafana/grafana" ]; then
        FORKED_BY=$(echo $GRAFANA_REPO | cut -d '/' -f 2)
        mkdir $GOPATH/src/github.com/grafana
        ln -s  $GOPATH/src/github.com/$FORKED_BY/grafana $GOPATH/src/github.com/grafana/grafana
    fi

    # Install Go source code
    cd $GOPATH/src/github.com/grafana/grafana
    go run build.go setup
    go run build.go build

    # Install frontend assets
    npm install
    npm run build
fi

echo "Setup complete!"

