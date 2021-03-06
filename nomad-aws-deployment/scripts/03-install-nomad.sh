#!/bin/bash

echo "Installing Nomad..."
curl -sfLo "nomad.zip" "${NOMAD_URL}"
sudo unzip nomad.zip -d /usr/local/bin/
rm -rf nomad.zip

echo "Add Nomad user..."
groupadd nomad
useradd nomad -g nomad

sudo bash -c "cat >/etc/nomad.d/vault-token.json" <<EOF
{
    "policies": [
        "nomad-server"
    ],
    "ttl": "72h",
    "renewable": true,
    "no_parent": true
}
EOF

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @/etc/nomad.d/vault-token.json \
    http://localhost:8200/v1/auth/token/create | jq . > /etc/nomad.d/token.json

export NOMAD_VAULT_TOKEN="$(cat /etc/nomad.d/token.json | jq -r .auth.client_token | tr -d '\n')"

echo "Get Consul ACL token for Nomad"

source /etc/environment

echo "Consul Token: $CONSUL_HTTP_TOKEN"

# Write the server policy
sudo bash -c "cat >/root/consul/nomad-server-policy.json" <<EOF
{
    "Name": "nomad-server",
    "Description": "Nomad Server Policy",
    "Rules": "agent_prefix \"\" {\n  policy = \"read\"\n}\n\nnode_prefix \"\" {\n  policy = \"read\"\n}\n\nservice_prefix \"\" {\n  policy = \"write\"\n}\n\nacl = \"write\""
}
EOF

echo "Waiting for ACL system to be ready"
sleep 30

# Create the server policy
echo "Create the server policy"
curl -s --request PUT --header "X-Consul-Token: $CONSUL_HTTP_TOKEN" --data @/root/consul/nomad-server-policy.json http://127.0.0.1:8500/v1/acl/policy

# Write the client policy
sudo bash -c "cat >/root/consul/nomad-client-policy.json" <<EOF
{
    "Name": "nomad-client",
    "Description": "Nomad Client Policy",
    "Rules": "agent_prefix \"\" {\n  policy = \"read\"\n}\n\nnode_prefix \"\" {\n  policy = \"read\"\n}\n\nservice_prefix \"\" {\n  policy = \"write\"\n}\n\nacl = \"write\""
}
EOF

# Create the client policy
echo "Create the client policy"
curl -s --request PUT --header "X-Consul-Token: $CONSUL_HTTP_TOKEN" --data @/root/consul/nomad-client-policy.json http://127.0.0.1:8500/v1/acl/policy

# Create a token for Nomad to use with Consul
sudo bash -c "cat >/root/consul/nomad-token-request.json" <<EOF
{
    "Description": "Nomad Token",
    "Policies": [
        { "Name": "nomad-server" },
        { "Name": "nomad-client" }
    ]
}
EOF

export NOMAD_CONSUL_TOKEN=`curl -s --request PUT --header "X-Consul-Token: $CONSUL_HTTP_TOKEN" --data @/root/consul/nomad-token-request.json http://127.0.0.1:8500/v1/acl/token | jq -r .SecretID`
echo -e "NOMAD_CONSUL_TOKEN=\"$NOMAD_CONSUL_TOKEN\"" >> /etc/environment

sudo bash -c "cat >/etc/nomad.d/nomad.hcl" <<EOF
data_dir  = "/opt/nomad"
plugin_dir = "/opt/nomad/plugins"
bind_addr = "0.0.0.0"
datacenter = "${REGION}"
enable_debug = true

ports {
    http = 4646
    rpc  = 4647
    serf = 4648
}

consul {
    address             = "127.0.0.1:8500"
    token               = "$NOMAD_CONSUL_TOKEN"
    server_service_name = "nomad-server"
    client_service_name = "nomad-clients"
    auto_advertise      = true
    server_auto_join    = true
    client_auto_join    = true
}

vault {
    enabled          = true
    address          = "http://vault.service.consul:8200"
    task_token_ttl   = "1h"
    create_from_role = "nomad-cluster"
    token            = "$NOMAD_VAULT_TOKEN"
}

server {
    enabled          = true
    bootstrap_expect = 1
}

acl {
    enabled = true
}

client {
    enabled       = true
    network_speed = 1000
    options {
        "driver.raw_exec.enable"    = "1"
        # "docker.auth.config"        = "/etc/docker/config.json"
        # "docker.auth.helper"        = "ecr-login"
        # "docker.privileged.enabled" = "true"
    }
    servers = ["nomad-server.service.${REGION}.consul:4647"]
    host_volume "pgdata" {
        path      = "/opt/postgres/data"
        read_only = false
    }
}
EOF

# Set Nomad up as a systemd service
echo "Installing systemd service for Nomad..."
sudo bash -c "cat >/etc/systemd/system/nomad.service" <<EOF
[Unit]
Description=Hashicorp Nomad
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
PIDFile=/var/run/nomad/nomad.pid
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d/nomad.hcl
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

echo "Update Nomad permissions..."
chown -R nomad:nomad /usr/local/bin/nomad
chown -R nomad:nomad /etc/nomad.d/
chown -R nomad:nomad /opt/nomad/
chown -R nomad:nomad /var/run/nomad/

echo "Start service..."
sudo systemctl start nomad
sudo systemctl enable nomad

curl \
    http://127.0.0.1:8500/v1/agent/service/register \
    --request PUT \
    --data @- <<PAYLOAD
{
    "ID": "nomad-server",
    "Name": "nomad-server",
    "Port": 4647
}
PAYLOAD

echo "Bootstrapping ACL system..."
sleep 10
curl -s \
    --request POST \
    http://127.0.0.1:4646/v1/acl/bootstrap > /root/nomad-init.txt

export NOMAD_TOKEN=`cat /root/nomad-init.txt | jq -r .SecretID`
echo -e "NOMAD_TOKEN=\"$NOMAD_TOKEN\"" >> /etc/environment


systemctl disable nginx
systemctl stop nginx

if [ ! -z "$NOMAD_LICENSE" ]; then
    curl \
        --header "X-Nomad-Token: $NOMAD_TOKEN" \
        --request PUT \
        --data "$NOMAD_LICENSE" \
        http://127.0.0.1:4646/v1/operator/license
fi

echo "Nomad installation complete."
