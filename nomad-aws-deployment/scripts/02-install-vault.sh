#!/bin/bash

echo "Installing Vault..."
curl -sfLo "vault.zip" "${VAULT_URL}"
sudo unzip vault.zip -d /usr/local/bin/
rm -rf vault.zip

echo "Add Vault user..."
groupadd vault
useradd vault -g vault

# Server configuration
sudo bash -c "cat >/etc/vault.d/vault.hcl" <<EOF
storage "file" {
  path = "/opt/vault"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

seal "awskms" {
    region = "${REGION}"
    kms_key_id = "${AWS_KMS_KEY_ID}"
}

ui = true
EOF

# Set Vault up as a systemd service
echo "Installing systemd service for Vault..."
sudo bash -c "cat >/etc/systemd/system/vault.service" <<EOF
[Unit]
Description=Hashicorp Vault
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
PIDFile=/var/run/vault/vault.pid
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

echo "Update Vault permissions..."
chown -R vault:vault /usr/local/bin/vault
chown -R vault:vault /etc/vault.d/
chown -R vault:vault /opt/vault/
chown -R vault:vault /var/log/vault/
chown -R vault:vault /var/run/vault/

echo "Start service..."
sudo systemctl start vault
sudo systemctl enable vault

sleep 5

echo "Initializing and setting up environment variables..."
export VAULT_ADDR=http://localhost:8200

vault operator init -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1 > /root/init.txt 2>&1

sleep 10

echo "Extracting vault root token..."
export VAULT_TOKEN=$(cat /root/init.txt | sed -n -e '/^Initial Root Token/ s/.*\: *//p')
echo "Root token is $VAULT_TOKEN"
consul kv put service/vault/root-token $VAULT_TOKEN
echo "Extracting vault recovery key..."
export RECOVERY_KEY=$(cat /root/init.txt | sed -n -e '/^Recovery Key 1/ s/.*\: *//p')
echo "Recovery key is $RECOVERY_KEY"
consul kv put service/vault/recovery-key $RECOVERY_KEY

echo -e "VAULT_ADDR=\"$VAULT_ADDR\"" >> /etc/environment
echo -e "VAULT_TOKEN=\"$VAULT_TOKEN\"" >> /etc/environment

sudo bash -c "cat >/etc/vault.d/nomad-policy.json" <<EOF
{
    "policy": "# Allow creating tokens under \"nomad-cluster\" token role. The token role name\n# should be updated if \"nomad-cluster\" is not used.\npath \"auth/token/create/nomad-cluster\" {\n  capabilities = [\"update\"]\n}\n\n# Allow looking up \"nomad-cluster\" token role. The token role name should be\n# updated if \"nomad-cluster\" is not used.\npath \"auth/token/roles/nomad-cluster\" {\n  capabilities = [\"read\"]\n}\n\n# Allow looking up the token passed to Nomad to validate # the token has the\n# proper capabilities. This is provided by the \"default\" policy.\npath \"auth/token/lookup-self\" {\n  capabilities = [\"read\"]\n}\n\n# Allow looking up incoming tokens to validate they have permissions to access\n# the tokens they are requesting. This is only required if\n# 'allow_unauthenticated' is set to false.\npath \"auth/token/lookup\" {\n  capabilities = [\"update\"]\n}\n\n# Allow revoking tokens that should no longer exist. This allows revoking\n# tokens for dead tasks.\npath \"auth/token/revoke-accessor\" {\n  capabilities = [\"update\"]\n}\n\n# Allow checking the capabilities of our own token. This is used to validate the\n# token upon startup.\npath \"sys/capabilities-self\" {\n  capabilities = [\"update\"]\n}\n\n# Allow our own token to be renewed.\npath \"auth/token/renew-self\" {\n  capabilities = [\"update\"]\n}\n"
}
EOF

sudo bash -c "cat >/etc/vault.d/access-creds.json" <<EOF
{
    "policy": "path \"secret/data/aws\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"secret/data/roottoken\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"custdbcreds/creds/cust-api-role\" {\n    capabilities = [\"list\", \"read\"]\n}\n"
}
EOF

sudo bash -c "cat >/etc/vault.d/nomad-cluster-role.json" <<EOF
{
    "disallowed_policies": "nomad-server",
    "explicit_max_ttl": 0,
    "name": "nomad-cluster",
    "orphan": true,
    "period": 259200,
    "renewable": true
}
EOF

echo "Configuring Vault..."

# Enable auditing
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data "{ \"description\": \"Primary Audit\", \"type\": \"file\", \"options\": { \"file_path\": \"/var/log/vault\" } }" \
    http://127.0.0.1:8200/v1/sys/audit/main-audit

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "kv", "options": { "version": "2" } }' \
    http://127.0.0.1:8200/v1/sys/mounts/secret

# curl \
#     --header "X-Vault-Token: $VAULT_TOKEN" \
#     --request PUT \
#     --data @/etc/vault.d/nomad-policy.json \
#     http://127.0.0.1:8200/v1/sys/policy/nomad-server

# curl \
#     --header "X-Vault-Token: $VAULT_TOKEN" \
#     --request PUT \
#     --data @/etc/vault.d/access-creds.json \
#     http://127.0.0.1:8200/v1/sys/policy/access-creds

# curl \
#     --header "X-Vault-Token: $VAULT_TOKEN" \
#     --request POST \
#     --data @/etc/vault.d/nomad-cluster-role.json \
#     http://127.0.0.1:8200/v1/auth/token/roles/nomad-cluster

echo "Enable transit engine..."
# enable transit
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type":"transit"}' \
    http://127.0.0.1:8200/v1/sys/mounts/transit

echo "Register with Consul"
curl \
    http://127.0.0.1:8500/v1/agent/service/register \
    --request PUT \
    --data @- <<PAYLOAD
{
    "ID": "vault",
    "Name": "vault",
    "Port": 8200
}
PAYLOAD

echo "Vault installation complete."
