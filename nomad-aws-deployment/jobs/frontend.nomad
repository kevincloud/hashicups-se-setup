job "frontend" {
    datacenters = ["us-east-1"]
    type     = "system"
  
    group "frontend" {
      count = 0
  
      restart {
        attempts = 10
        interval = "5m"
        delay    = "15s"
        mode     = "delay"
      }
  
      task "server" {
        env {
          PORT    = "${NOMAD_PORT_http}"
          NODE_IP = "${NOMAD_IP_http}"
        }
  
        driver = "docker"
  
        config {
          image = "hashicorpdemoapp/frontend:v0.0.3"
          dns_servers = ["172.17.0.1"]
          volumes = [
            "local:/etc/nginx/conf.d",
          ]
        }
  
        template {
          data = "server {\n      listen 80;\n      server_name  localhost;\n      location / {\n          root   /usr/share/nginx/html;\n          index  index.html index.htm;\n      }\n      location /api {\n          proxy_pass http://public-api-server.service.consul:8080;\n      }\n      error_page   500 502 503 504  /50x.html;\n      location = /50x.html {\n          root   /usr/share/nginx/html;\n      }\n}"
          destination   = "local/default.conf"
          change_mode   = "signal"
          change_signal = "SIGHUP"
        }
  
        resources {
          network {
            mbits = 10
            port  "http"{
              static = 80
            }
          }
        }
  
        service {
          name = "frontend"
          port = "http"
  
          check {
            type     = "http"
            path     = "/"
            interval = "2s"
            timeout  = "2s"
          }
        }
      }
    }
  }
