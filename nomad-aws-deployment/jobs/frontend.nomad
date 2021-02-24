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
          data = <<EOF
  server {
      listen       80;
      server_name  localhost;
      #charset koi8-r;
      #access_log  /var/log/nginx/host.access.log  main;
      location / {
          root   /usr/share/nginx/html;
          index  index.html index.htm;
      }
      # Proxy pass the api location to save CORS
      # Use location exposed by Consul connect
      location /api {
          proxy_pass http://public-api-server.service.consul:8080;
      }
      error_page   500 502 503 504  /50x.html;
      location = /50x.html {
          root   /usr/share/nginx/html;
      }
  }
  EOF
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
  
          tags = [
            # "traefik.enable=true",
            # "traefik.http.routers.frontend.rule=Path(`/frontend`)",
          ]
  
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
