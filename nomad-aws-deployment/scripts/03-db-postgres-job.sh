#!/bin/bash

sudo bash -c "cat >/root/jobs/db-postgres.json" <<EOF
{
  "Job": {
    "ID": "postgres",
    "Name": "postgres",
    "Type": "service",
    "Priority": 50,
    "Datacenters": ["$REGION"],
    "TaskGroups": [
      {
        "Name": "postgres",
        "Count": 1,
        "Update": {
          "MinHealthyTime": 5000000000,
          "HealthyDeadline": 180000000000
        },
        "RestartPolicy": {
          "Attempts": 10,
          "Interval": 300000000000,
          "Delay": 25000000000,
          "Mode": "delay"
        },
        "Tasks": [
          {
            "Name": "postgres",
            "Driver": "docker",
            "User": "",
            "Config": {
              "image": "hashicorpdemoapp/product-api-db:v0.0.11",
              "network_mode": "host",
              "port_map": [{ "db": 5432 }]
            },
            "Env": {
              "POSTGRES_DB": "$DB_INSTANCE",
              "POSTGRES_USER": "$DB_USERNAME",
              "POSTGRES_PASSWORD": "$DB_PASSWORD"
            },
            "Services": [
              {
                "Name": "postgres",
                "PortLabel": "db",
                "Checks": [
                  {
                    "Name": "alive",
                    "Type": "tcp",
                    "Interval": 10000000000,
                    "Timeout": 2000000000
                  }
                ]
              }
            ],
            "Resources": {
              "CPU": 100,
              "MemoryMB": 300,
              "Networks": [{
                  "ReservedPorts": [{
                      "Label": "db",
                      "Value": 5432
                  }]
              }]
            },
            "LogConfig": {
              "MaxFiles": 5,
              "MaxFileSizeMB": 15
            },
            "VolumeMounts": [
              {
                "Volume": "pgdata",
                "Destination": "/var/lib/postgresql/data",
                "ReadOnly": false
              }
            ]
          }
        ],
        "EphemeralDisk": {
          "Sticky": false,
          "SizeMB": 300,
          "Migrate": false
        },
        "Volumes": {
          "pgdata": {
            "Name": "pgdata",
            "Type": "host",
            "Source": "pgdata",
            "ReadOnly": false
          }
        }
      }
    ],
    "Update": {
      "MaxParallel": 1,
      "MinHealthyTime": 0,
      "HealthyDeadline": 0,
      "AutoRevert": false,
      "Canary": 0
    }
  }
}
EOF
