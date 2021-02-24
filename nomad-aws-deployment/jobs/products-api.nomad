job "products-api" {
  datacenters = ["us-east-1"]
  type = "service"

  group "products-api" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "products-api" {
      driver = "docker"

      template {
        destination   = "/secrets/db-creds"
        data = <<EOF
{
  "db_connection": "host=postgres.service.consul port=5432 user=root password=password dbname=products sslmode=disable",
  "bind_address": ":9090",
  "metrics_address": ":9103"
}
EOF
      }

      env {
        CONFIG_FILE = "/secrets/db-creds"
      }
      config {
        image = "hashicorpdemoapp/product-api:v0.0.11"
        dns_servers = ["172.17.0.1"]
        port_map {
          http_port = 9090
        }
      }
      resources {
        #cpu    = 500
        #memory = 1024
        network {
          #mbits = 10
          port  "http_port"  {
            static = 9090
          }
        }
      }
      service {
        name = "products-api-server"
        port = "http_port"
        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
