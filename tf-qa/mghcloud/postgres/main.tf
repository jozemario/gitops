
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
  
}

module "shared" {
  source = "../../shared"
}


resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "postgres"
      managed-by  = "terraform"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          image = "postgres:13.3"
          name  = "postgres-container"
          env {
            name  = "POSTGRES_DB"
            value = module.shared.config.postgres_database
          }
          env {
            name  = "POSTGRES_USER"
            value = module.shared.config.postgres_user
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = module.shared.config.postgres_password
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }
          port {
            name = "postgres"
            container_port = 5432
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data/pgdata"
            sub_path   = "postgres"
            name = "postgres-pvc"
          }
          
        }
        volume {
          name = "postgres-pvc"
          persistent_volume_claim {
            claim_name = "postgres-pvc"
          }
        }
            
      }
    }
  }
}
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "postgres"
      managed-by  = "terraform"
    }
  }
  spec {
    selector = {
      app = "postgres"
    }
    type = "NodePort"
    port {
      name        = "postgres"
      node_port   = 30204
      port        = 5432
      target_port = 5432
    }

  }
}

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgres-pvc"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "postgres"
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

