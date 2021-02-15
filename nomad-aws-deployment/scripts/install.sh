#!/bin/bash

echo "Starting installation..."

echo "...updating package repos..."
sudo apt-get -y update > /dev/null 2>&1

echo "...installing system packages"
echo "      unzip (1 of 10)"
sudo apt-get install -y unzip > /dev/null 2>&1
echo "      git (2 of 10)"
sudo apt-get install -y git > /dev/null 2>&1
echo "      jq (3 of 10)"
sudo apt-get install -y jq > /dev/null 2>&1
echo "      python3 (4 of 10)"
sudo apt-get install -y python3 > /dev/null 2>&1
echo "      python3-pip (5 of 10)"
sudo apt-get install -y python3-pip > /dev/null 2>&1
echo "      python3-dev (6 of 10)"
sudo apt-get install -y python3-dev > /dev/null 2>&1
echo "      dnsmasq (7 of 10)"
sudo apt-get install -y dnsmasq > /dev/null 2>&1
echo "      npm (8 of 10)"
sudo apt-get install -y npm > /dev/null 2>&1
echo "      docker.io (9 of 10)"
sudo apt-get install -y docker.io > /dev/null 2>&1
echo "      nginx (10 of 10)"
sudo apt-get install -y nginx > /dev/null 2>&1
echo "   done"

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
