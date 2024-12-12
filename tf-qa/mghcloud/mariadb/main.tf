
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
  
}

resource "kubernetes_deployment" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "mariadb"
      managed-by  = "terraform"
    }
  }
  spec {
    replicas = 2
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
          image = "mariadb:10.5.4-focal"
          name  = "mariadb-container"
          env {
            name  = "MYSQL_DATABASE"
            value = output.config.mariadb_database
          }
          env {
            name  = "MYSQL_USER"
            value = output.config.mariadb_user
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = output.config.mariadb_password
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = output.config.mariadb_root_password
          }

          port {
            name = "mariadb"
            container_port = 3306
          }

          volume_mount {
            mount_path = "/var/lib/mysql"
            sub_path   = "mysql"
            name = "mariadb-pvc"
          }

          volume_mount {
            mount_path = "/etc/mysql/conf.d"
            name = "mariadb-config"
          }

        }
        volume {
          name = "mariadb-pvc"
          persistent_volume_claim {
            claim_name = "mariadb-pvc"
          }
        }

        volume {
          name = "mariadb-config"
          config_map {
            name = "mariadb-config"
          }
        }

      }
    }
  }
}

resource "kubernetes_service" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "mariadb"
      managed-by  = "terraform"
    }
  }
  spec {
    selector = {
      app = "mariadbApp"
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

resource "kubernetes_config_map" "mariadb-config" {
  metadata {
    name      = "mariadb-config"
    namespace = "qa"
  }
  data = {
    "mariadb.cnf" = file("${path.module}/mariadb.cnf")
  }
}

resource "kubernetes_persistent_volume_claim" "mariadb-pvc" {
  metadata {
    name      = "mariadb-pvc"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "mariadb"
      managed-by  = "terraform"
    }
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = "nfs"
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}


resource "kubernetes_ingress_v1" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = "qa"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-production"
      "kubernetes.io/ingress.class"    = "traefik"
    }
    labels = {
      app = "mariadb"
    }
  }
  spec {
    rule {
      host = "mariadb.qa.mghcloud.com"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "mariadb"
              port {
                number = 3306
              }
            }
          }
        }
      }
    }
  }
}