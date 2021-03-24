#!/bin/bash

echo "Starting installation..."
if [ ! -z "${SLACK_URL}" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Nomad Server: Starting installation and configuration..."}' ${SLACK_URL}
fi

echo "...updating package repos..."
sudo apt-get -y update > /dev/null 2>&1

echo "...installing system packages"
echo "      unzip (1 of 9)"
sudo apt-get install -y unzip > /dev/null 2>&1
echo "      git (2 of 9)"
sudo apt-get install -y git > /dev/null 2>&1
echo "      jq (3 of 9)"
sudo apt-get install -y jq > /dev/null 2>&1
echo "      python3 (4 of 9)"
sudo apt-get install -y python3 > /dev/null 2>&1
echo "      python3-pip (5 of 9)"
sudo apt-get install -y python3-pip > /dev/null 2>&1
echo "      python3-dev (6 of 9)"
sudo apt-get install -y python3-dev > /dev/null 2>&1
echo "      dnsmasq (7 of 9)"
sudo apt-get install -y dnsmasq > /dev/null 2>&1
echo "      npm (8 of 9)"
sudo apt-get install -y npm > /dev/null 2>&1
echo "      docker.io (9 of 9)"
sudo apt-get install -y docker.io > /dev/null 2>&1
echo "   done"

echo "...installing python libraries"
pip3 install botocore
pip3 install boto3
pip3 install awscli

echo "...creating directories"
mkdir -p /root/jobs
mkdir -p /root/consul
mkdir -p /etc/consul.d/server
mkdir -p /etc/consul.d/template
mkdir -p /etc/vault.d
mkdir -p /etc/nomad.d
mkdir -p /etc/docker
mkdir -p /opt/consul
mkdir -p /opt/nomad
mkdir -p /opt/nomad/plugins
mkdir -p /opt/postgres/data
mkdir -p /var/log/vault
mkdir -p /var/run/consul
mkdir -p /var/run/vault
mkdir -p /var/run/nomad

echo "...setting environment variables"
export AWS_KMS_KEY_ID="${AWS_KMS_KEY_ID}"
export REGION="${REGION}"
export CONSUL_URL="${CONSUL_URL}"
export CONSUL_LICENSE="${CONSUL_LICENSE}"
export CONSUL_JOIN_KEY="${CONSUL_JOIN_KEY}"
export CONSUL_JOIN_VALUE="${CONSUL_JOIN_VALUE}"
export VAULT_URL="${VAULT_URL}"
export VAULT_LICENSE="${VAULT_LICENSE}"
export NOMAD_URL="${NOMAD_URL}"
export NOMAD_LICENSE="${NOMAD_LICENSE}"
export DB_USERNAME="root"
export DB_PASSWORD="password"
export DB_INSTANCE="products"
export KEY_PAIR_NAME="${KEY_PAIR_NAME}"
export CLIENT_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
export PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

echo $CLIENT_IP $(echo "ip-$CLIENT_IP" | sed "s/\./-/g") >> /etc/hosts

echo "...cloning repo"
cd /root
git clone --branch "${BRANCH_NAME}" https://github.com/kevincloud/hashicups-se-setup.git

if [ ! -z "${SLACK_URL}" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Nomad Server: Base install is complete. Continuing to Consul..."}' ${SLACK_URL}
fi

cd /root/hashicups-se-setup/nomad-aws-deployment/

echo "...installing Consul"
. ./scripts/01-install-consul.sh

if [ ! -z "${SLACK_URL}" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Nomad Server: Consul install is complete. Continuing to Vault..."}' ${SLACK_URL}
fi

echo "...installing Vault"
. ./scripts/02-install-vault.sh

if [ ! -z "${SLACK_URL}" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Nomad Server: Vault install is complete. Continuing to Nomad..."}' ${SLACK_URL}
fi

echo "...installing Nomad"
. ./scripts/03-install-nomad.sh

if [ ! -z "${SLACK_URL}" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Nomad Server: Nomad install is complete. Creating jobs..."}' ${SLACK_URL}
fi

echo "...creating Nomad jobs"
. ./scripts/04-db-postgres-job.sh
. ./scripts/05-products-api-job.sh
. ./scripts/06-payments-api-job.sh
. ./scripts/07-public-api-job.sh
. ./scripts/08-frontend-job.sh

if [ ! -z "${SLACK_URL}" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Nomad Server: Job files have been created. Submitting jobs..."}' ${SLACK_URL}
fi

echo "...submitting jobs"
. ./scripts/09-run-jobs.sh

if [ ! -z "${SLACK_URL}" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Nomad Server: Installation and configuration is complete!\nConsul UI:http://'$PUBLIC_IP':8500\nConsul token: '$CONSUL_HTTP_TOKEN'\nVault UI: http://'$PUBLIC_IP':8200\nVault token: '$VAULT_TOKEN'\nNomad UI:http://'$PUBLIC_IP':4646\nNomad token: '$NOMAD_TOKEN'\nSSH Login: ssh -i ~/keys/'$KEY_PAIR_NAME'.pem ubuntu@'$PUBLIC_IP'\nHashiCups UI: http://'$PUBLIC_IP'"}' ${SLACK_URL}
fi

echo "All done!"

#
