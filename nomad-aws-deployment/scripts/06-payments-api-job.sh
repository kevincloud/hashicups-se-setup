#!/bin/bash

sudo bash -c "cat >/root/jobs/payments-api.json" <<EOF
{
  "Job": {
    "ID": "payments-api",
    "Name": "payments-api",
    "Type": "service",
    "Priority": 50,
    "Datacenters": ["$REGION"],
    "TaskGroups": [
      {
        "Name": "payments-api",
        "Count": 1,
        "Update": {
          "MinHealthyTime": 10000000000,
          "HealthyDeadline": 300000000000
        },
        "RestartPolicy": {
          "Attempts": 10,
          "Interval": 300000000000,
          "Delay": 25000000000,
          "Mode": "delay"
        },
        "Tasks": [
          {
            "Name": "payments-api",
            "Driver": "docker",
            "Config": {
              "ports": [ "payments" ],
              "image": "jubican/payments:v0.0.10",
              "args": [
                "--spring.config.location=file:/local/application.properties",
                "--spring.config.location=file:/secrets/bootstrap.yaml"
              ]
            },
            "Services": [
              {
                "Name": "payments-api",
                "PortLabel": "payments"
              }
            ],
            "Templates": [
              {
                "DestPath": "/secrets/bootstrap.yaml",
                "EmbeddedTmpl": "spring:\n  cloud:\n    vault:\n      enabled: true\n      fail-fast: true\n      authentication: TOKEN\n      token: $VAULT_TOKEN\n      host: vault.service.consul\n      port: 8200\n      scheme: http\n"
              },
              {
                "DestPath": "/local/application.properties",
                "EmbeddedTmpl": "app.storage=redis\napp.encryption.enabled=true\napp.encryption.path=transit\napp.encryption.key=payments\nspring.redis.host=localhost\nspring.redis.port=6379"
              }
            ],
            "Resources": {
              "Networks": [
                {
                  "DNS": {
                    "Servers": ["169.254.1.1"]
                  }
                }
              ]
            }
          }
        ],
        "Networks": [
          {
            "DNS": {
              "Servers": ["169.254.1.1"]
            },
            "ReservedPorts": [{
              "Label": "payments",
              "Value": 18000,
              "To": 8080
            }]
          }
        ]
      }
    ]
  }
}
EOF

              # "args": [
              #   "--spring.config.location=file:/secrets/bootstrap.yaml"
              # ]
