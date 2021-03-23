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
              "image": "hashicorpdemoapp/payments:v0.0.10"
            },
            "Services": [
              {
                "Name": "payments-api",
                "PortLabel": "payments"
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
            "Value": 1800,
            "To": 8080
            }]
          }
        ]
      }
    ]
  }
}
EOF
