# https://github.com/hashicorp-demoapp/public-api/blob/master/main.go
job "public-api" {
  datacenters = ["us-east-1"]
  type = "service"

  group "public-api" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "public-api" {
      driver = "docker"

      env {
        BIND_ADDRESS = ":8080"
        PRODUCTS_API_URI = "http://products-api-server.service.consul:9090"
      }

      config {
        image = "hashicorpdemoapp/public-api:v0.0.1"
        dns_servers = ["172.17.0.1"]

        port_map {
          pub_api = 8080
        }
      }

      resources {
        #cpu    = 500
        #memory = 1024

        network {
          port "pub_api" {
            static = 8080
          }
        }
      }
      service {
        name = "public-api-server"
        port = "pub_api"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.public.rule=Path(`/public`)",
        ]
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
