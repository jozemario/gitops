terraform {
  required_version = ">= 1.3.9"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

variable "branch" {
   type = string
   default = "qa"
   description = "QA Branch"
}


# Create MariaDB Secret
resource "kubernetes_secret" "mariadb" {
  metadata {
    name      = "mariadb-secret"
    namespace = "dev"
  }

  data = {
    MYSQL_ROOT_PASSWORD = "UGFzc3dvcmQxMjMh" # base64 encoded "Password123!"
    MYSQL_DATABASE     = "testdb"
  }
}

# Create MariaDB Deployment
resource "kubernetes_deployment" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = "dev"
    labels = {
      app = "mariadb"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mariadb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mariadb"
        }
      }

      spec {
        container {
          image = "mariadb:10.6"
          name  = "mariadb"

          port {
            container_port = 3306
          }

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MYSQL_ROOT_PASSWORD"
              }
            }
          }

          env {
            name = "MYSQL_DATABASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MYSQL_DATABASE"
              }
            }
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# Create MariaDB Service
resource "kubernetes_service" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = "dev"
  }
  spec {
    selector = {
      app = kubernetes_deployment.mariadb.metadata[0].labels.app
    }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}

output "hello_world" {
  value = "Welcome to QA - ${var.branch} branch!"
}

output "mariadb_connection_string" {
  value = "mysql -h ${kubernetes_service.mariadb.metadata[0].name}.dev.svc.cluster.local -P 3306 -u root -p"
}
