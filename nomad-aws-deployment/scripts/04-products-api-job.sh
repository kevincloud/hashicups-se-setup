#!/bin/bash

sudo bash -c "cat >/root/jobs/products-api.json" <<EOF
{
  "Job": {
    "ID": "products-api",
    "Name": "products-api",
    "Type": "service",
    "Priority": 50,
    "Datacenters": ["$REGION"],
    "TaskGroups": [
      {
        "Name": "products-api",
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
            "Name": "products-api",
            "Driver": "docker",
            "Config": {
              "dns_servers": ["127.0.0.1:8600"],
              "port_map": [{ "http_port": 9090 }],
              "image": "hashicorpdemoapp/product-api:v0.0.11"
            },
            "Env": {
              "CONFIG_FILE": "/secrets/db-creds"
            },
            "Services": [
              {
                "Name": "products-api-server",
                "PortLabel": "http_port",
                "Checks": [
                  {
                    "Name": "service: \"products-api-server\" check",
                    "Type": "http",
                    "Path": "/health",
                    "Interval": 10000000000,
                    "Timeout": 2000000000
                  }
                ]
              }
            ],
            "Templates": [
              {
                "DestPath": "/secrets/db-creds",
                "EmbeddedTmpl": "{\n  \"db_connection\": \"host=postgres.service.consul port=5432 user=$DB_USERNAME password=$DB_PASSWORD dbname=$DB_INSTANCE sslmode=disable\",\n  \"bind_address\": \":9090\",\n  \"metrics_address\": \":9103\"\n}\n"
              }
            ],
            "Resources": {
              "Networks": [
                {
                  "DNS": {
                    "Servers": ["169.254.1.1"]
                  },
                  "ReservedPorts": [{
                    "Label": "http_port",
                    "Value": 9090
                  }]
                }
              ]
            }
          }
        ],
        "Networks": [
          {
            "DNS": {
              "Servers": ["169.254.1.1"]
            }
          }
        ]
      }
    ]
  }
}
EOF
