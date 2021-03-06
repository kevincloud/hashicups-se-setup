#!/bin/bash

sudo bash -c "cat >/root/jobs/public-api.json" <<EOF
{
  "Job": {
    "ID": "public-api",
    "Name": "public-api",
    "Type": "service",
    "Priority": 50,
    "Datacenters": ["$REGION"],
    "TaskGroups": [
      {
        "Name": "public-api",
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
            "Name": "public-api",
            "Driver": "docker",
            "User": "",
            "Config": {
              "port_map": [{ "pub_api": 8080 }],
              "image": "hashicorpdemoapp/public-api:v0.0.4"
            },
            "Env": {
              "BIND_ADDRESS": ":8080",
              "PRODUCT_API_URI": "http://products-api-server.service.consul:9090",
              "PAYMENT_API_URI": "http://payments-api.service.consul:18000"
            },
            "Services": [
              {
                "Name": "public-api-server",
                "PortLabel": "pub_api",
                "Checks": [
                  {
                    "Name": "service: \"public-api-server\" check",
                    "Type": "tcp",
                    "Interval": 10000000000,
                    "Timeout": 2000000000
                  }
                ]
              }
            ],
            "Resources": {
              "Networks": [{
                  "DNS": {
                    "Servers": ["169.254.1.1"]
                  },
                  "ReservedPorts": [{
                    "Label": "pub_api",
                    "Value": 8080
                  }]
              }]
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
