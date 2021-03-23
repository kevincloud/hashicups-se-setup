#!/bin/bash

sudo bash -c "cat >/root/jobs/frontend.json" <<EOF
{
  "Job": {
    "ID": "frontend",
    "Name": "frontend",
    "Type": "system",
    "Priority": 50,
    "Datacenters": ["us-east-1"],
    "TaskGroups": [
      {
        "Name": "frontend",
        "Count": 1,
        "RestartPolicy": {
          "Attempts": 10,
          "Interval": 300000000000,
          "Delay": 15000000000,
          "Mode": "delay"
        },
        "Tasks": [
          {
            "Name": "server",
            "Driver": "docker",
            "Config": {
              "image": "hashicorpdemoapp/frontend:v0.0.4",
              "volumes": [
                "local:/etc/nginx/conf.d"
              ]
            },
            "Env": {
              "NODE_IP": "\${NOMAD_IP_http}",
              "PORT": "\${NOMAD_PORT_http}"
            },
            "Services": [
              {
                "Name": "frontend",
                "PortLabel": "http",
                "Checks": [
                  {
                    "Name": "service: \"frontend\" check",
                    "Type": "http",
                    "Path": "/",
                    "Interval": 2000000000,
                    "Timeout": 2000000000
                  }
                ]
              }
            ],
            "Templates": [
              {
                "DestPath": "local/default.conf",
                "EmbeddedTmpl": "server {\n      listen 80;\n      server_name  localhost;\n      location / {\n          root   /usr/share/nginx/html;\n          index  index.html index.htm;\n      }\n      location /api {\n          proxy_pass http://public-api-server.service.consul:8080;\n          proxy_http_version 1.1;\n          proxy_set_header Upgrade $http_upgrade;\n          proxy_set_header Connection "Upgrade";\n          proxy_set_header Host $host;\n      }\n      error_page   500 502 503 504  /50x.html;\n      location = /50x.html {\n          root   /usr/share/nginx/html;\n      }\n}",
                "ChangeMode": "signal",
                "ChangeSignal": "SIGHUP"
              }
            ],
            "Resources": {
              "Networks": [
                {
                  "MBits": 10,
                  "DNS": {
                    "Servers": ["169.254.1.1"]
                  },
                  "ReservedPorts": [
                    {
                      "Label": "http",
                      "Value": 80
                    }
                  ]
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
