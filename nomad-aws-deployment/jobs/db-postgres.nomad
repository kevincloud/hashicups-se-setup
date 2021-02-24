# To Configure vault
# vault secrets enable database
# vault write database/config/postgresql  plugin_name=postgresql-database-plugin   connection_url="postgresql://{{username}}:{{password}}@postgres.service.consul:5432/postgres?sslmode=disable"   allowed_roles="*"     username="root"     password="rootpassword"
# vault write database/roles/readonly db_name=postgresql     creation_statements=@readonly.sql     default_ttl=1h max_ttl=24h

job "postgres" {
  datacenters = ["us-east-1"]
  type = "service"

  group "postgres" {
    count = 1

    volume "pgdata" {
      type      = "host"
      read_only = false
      source    = "pgdata"
    }

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    task "postgres" {
      driver = "docker"

      volume_mount {
        volume      = "pgdata"
        destination = "/var/lib/postgresql/data"
        read_only   = false
        }

     config {
        image = "hashicorpdemoapp/product-api-db:v0.0.11"
        dns_servers = ["172.17.0.1"]
        network_mode = "host"
        port_map {
          db = 5432
        }

      }
      env {
          POSTGRES_USER="root"
          POSTGRES_PASSWORD="password"
          POSTGRES_DB="products"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      resources {
        cpu = 100 #1000
        memory = 300 #1024
        network {
          #mbits = 10
          port  "db"  {
            static = 5432
          }
        }
      }

      service {
        name = "postgres"
        port = "db"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }

  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}
