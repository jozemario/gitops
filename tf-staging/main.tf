terraform {
  required_version = ">= 1.3.9"
}

# variable "subject" {
#    type = string
#    default = "World"
#    description = "Subject to hello"
# }

# output "hello_world" {
#   value = "Hello TF Controller v0.16.0-rc.2, ${var.subject}!"
# }

# resource "kubernetes_namespace" "mariadb8ks" {
#   metadata {
#     name = "mariadb"
#   }
# }
resource "kubernetes_deployment" "mariadb8ks" {
  metadata {
    name      = "mariadb"
    #namespace = kubernetes_namespace.mariadb8ks.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mariadbApp"
      }
    }
    template {
      metadata {
        labels = {
          app = "mariadbApp"
        }
      }
      spec {
        container {
          #docker pull mariadb:10.5.4-focal
          #image = "mariadb:10.5.4"
          image = "mariadb:10.5.4-focal"
          #image = "mariadb"
          name  = "mariadb-container"
          env {
            name  = "MYSQL_DATABASE"
            value = "mysql"
          }
          env {
            name  = "MYSQL_USER"
            value = "mysql"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = "P0o9i8u7y6"
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "P0o9i8u7y6"
          }

          port {
            name = "mariadb"
            container_port = 3306
          }

          #           volume_mount {
          #             mount_path = "/var/lib/mysql"
          #             name = "mariadb-pvc"
          #           }

        }
        #         volume {
        #           name = "mariadb-pvc"
        #           persistent_volume_claim {
        #             claim_name = "mariadb-pvc"
        #           }
        #         }

      }
    }
  }
}
resource "kubernetes_service" "mariadb8ks" {
  metadata {
    name      = "mariadb"
    #namespace = kubernetes_namespace.mariadb8ks.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.mariadb8ks.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      name        = "mariadb"
      node_port   = 30005
      port        = 3306
      target_port = 3306
    }
  }
}