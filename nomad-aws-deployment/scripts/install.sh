#!/bin/bash

echo "Starting installation..."

echo "...updating package repos..."
sudo apt-get -y update > /dev/null 2>&1

echo "...installing system packages"
sudo apt-get install -y \
    unzip \
    git \
    jq \
    python3 \
    python3-pip \
    python3-dev \
    dnsmasq \
    npm \
    docker.io \
    nginx > /dev/null 2>&1

echo "...installing python libraries"
pip3 install botocore
pip3 install boto3
pip3 install awscli

echo "...creating directories"
mkdir -p /root/.aws
mkdir -p /root/jobs
mkdir -p /root/consul
mkdir -p /etc/consul.d/server
mkdir -p /etc/consul.d/template
mkdir -p /etc/nomad.d
mkdir -p /etc/docker
mkdir -p /opt/consul
mkdir -p /opt/nomad
mkdir -p /opt/nomad/plugins
mkdir -p /var/run/consul

echo "...setting environment variables"
export AWS_KMS_KEY_ID="${AWS_KMS_KEY_ID}"
export REGION="${REGION}"
export CONSUL_URL="${CONSUL_URL}"
export CONSUL_LICENSE="${CONSUL_LICENSE}"
export CONSUL_JOIN_KEY="${CONSUL_JOIN_KEY}"
export CONSUL_JOIN_VALUE="${CONSUL_JOIN_VALUE}"
export NOMAD_URL="${NOMAD_URL}"
export NOMAD_LICENSE="${NOMAD_LICENSE}"
export CLIENT_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

echo $CLIENT_IP $(echo "ip-$CLIENT_IP" | sed "s/\./-/g") >> /etc/hosts

echo "...cloning repo"
cd /root
git clone --branch "${BRANCH_NAME}" https://github.com/kevincloud/hashicups-se-setup.git


cd /root/hashicups-se-setup/nomad-aws-deployment/

echo "...installing Consul"
. ./scripts/01-install-consul.sh

echo "...installing Nomad"
. ./scripts/02-install-nomad.sh

echo "All done!"

#