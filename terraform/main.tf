#https://weaveworks.github.io/tf-controller/getting_started/
terraform {
  #required_version = ">= 1.5.5"
  required_version = ">= 0.15.1"
}

# variable "subject" {
#    type = string
#    default = "tfctl-rc"
#    description = "Subject to hello"
# }
#
# output "hello_world" {
#   value = "hey hey ya, ${var.subject}!"
# }

resource "kubernetes_namespace" "mariadb8ks" {
  metadata {
    name = "mariadb"
  }
}
resource "kubernetes_deployment" "mariadb8ks" {
  metadata {
    name      = "mariadb"
    namespace = kubernetes_namespace.mariadb8ks.metadata.0.name
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

          volume_mount {
            mount_path = "/var/lib/mysql"
            name = "mariadb-pvc"
          }

        }
        volume {
          name = "mariadb-pvc"
          persistent_volume_claim {
            claim_name = "mariadb-pvc"
          }
        }

      }
    }
  }
}
resource "kubernetes_service" "mariadb8ks" {
  metadata {
    name      = "mariadb"
    namespace = kubernetes_namespace.mariadb8ks.metadata.0.name
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

resource "kubernetes_persistent_volume_claim" "mariadb8ks" {
  metadata {
    name      = "mariadb-pvc"
    labels = {
      app = "mariadbApp"
    }
    namespace = kubernetes_namespace.mariadb8ks.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = ""
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    volume_name = "mariadb-pv"
  }
}

## NFS Server as persistent volume
resource "kubernetes_persistent_volume" "mariadb8ks" {
  metadata {
    name = "mariadb-pv"
    labels = {
      app = "mariadbApp"
    }
    #namespace = kubernetes_namespace.mariadb8ks.metadata.0.name
  }
  spec {
    capacity = {
      storage = "5Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Delete"
    persistent_volume_source {
      nfs {
        path   = "/var/uolshare/mariadb"
        server = "ec2-34-216-204-56.us-west-2.compute.amazonaws.com"
        read_only = "false"
      }
    }
    claim_ref {
      namespace = kubernetes_namespace.mariadb8ks.metadata.0.name
      name = "mariadb-pvc"
    }
  }
}
