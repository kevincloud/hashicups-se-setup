#!/bin/bash

sudo bash -c "cat >/root/jobs/nginx-proxy.json" <<EOF
{
  "Job": {
    "ID": "nginx-proxy",
    "Name": "nginx-proxy",
    "Type": "system",
    "Priority": 75,
    "Datacenters": [
      "us-east-1"
    ],
    "TaskGroups": [
      {
        "Name": "nginx-proxy",
        "Count": 1,
        "Update": {
          "MinHealthyTime": 10000000000,
          "HealthyDeadline": 300000000000
        },
        "Tasks": [
          {
            "Name": "nginx-proxy",
            "Driver": "docker",
            "Config": {
              "port_map": [
                {
                  "http": 8085
                }
              ],
              "image": "nginx",
              "volumes": [
                "local:/etc/nginx/conf.d"
              ]
            },
            "Services": [
              {
                "Name": "nginx-proxy",
                "PortLabel": "http",
                "Tags": ["nginx-proxy"],
                "Checks": [
                  {
                    "Name": "nginx alive",
                    "Type": "tcp",
                    "PortLabel": "http",
                    "Interval": 10000000000,
                    "Timeout": 2000000000
                  }
                ]
              }
            ],
            "Templates": [
              {
                "DestPath": "local/load-balancer.conf",
                "EmbeddedTmpl": "upstream myapp {\n    ip_hash;\n{{ range service \"demo-webapp\" }}\n  server {{ .Address }}:{{ .Port }};\n{{ else }}server 127.0.0.1:65535; # force a 502\n{{ end }}\n}\n\nupstream chat {\n    ip_hash;\n{{ range service \"chat-app\" }}\n  server {{ .Address }}:{{ .Port }};\n{{ else }}server 127.0.0.1:65535; # force a 502\n{{ end }}\n}\nserver {\n   listen 8085;\n\n   location /myapp/ {\n      proxy_pass http://myapp;\n   }\n\n     location / {\n      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n      proxy_set_header Host \$host;\n\n      proxy_pass http://chat;\n\n      # enable WebSockets\n      proxy_http_version 1.1;\n      proxy_set_header Upgrade \$http_upgrade;\n      proxy_set_header Connection \"upgrade\";\n    }\n\n    location /chat/ {\n      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n      proxy_set_header Host \$host;\n\n      proxy_pass http://chat;\n\n      # enable WebSockets\n      proxy_http_version 1.1;\n      proxy_set_header Upgrade \$http_upgrade;\n      proxy_set_header Connection \"upgrade\";\n    }\n\n\n     location  /socket.io/ {\n      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n      proxy_set_header Host \$host;\n\n      proxy_pass http://chat;\n\n      # enable WebSockets\n      proxy_http_version 1.1;\n      proxy_set_header Upgrade \$http_upgrade;\n      proxy_set_header Connection \"upgrade\";\n    }\n\n\n  }\n",
                "ChangeMode": "signal",
                "ChangeSignal": "SIGHUP"
              }
            ],
            "Resources": {
              "Networks": [
                {
                  "MBits": 10,
                  "ReservedPorts": [
                    {
                      "Label": "http",
                      "Value": 8085
                    }
                  ]
                }
              ]
            }
          }
        ]
      }
    ]
  }
}
EOF
