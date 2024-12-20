
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


resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "redis"
      managed-by  = "terraform"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "redis"
      }
    }
    template {
      metadata {
        labels = {
          app = "redis"
        }
      }
      spec {
        container {
          name  = "redis-container"
          image = "redis:alpine"
          port {
            container_port = 6379
          }
          volume_mount {
            mount_path = "/data"
            name = "redis-pvc"
          }
          volume_mount {
            mount_path = "/usr/local/etc/redis"
            name = "redis-conf"
            read_only = false
          }
        }
        restart_policy = "Always"
        volume {
          name = "redis-pvc"
          persistent_volume_claim {
            claim_name = "redis-pvc"
          }
        }
        volume {
          name = "redis-conf"
          config_map {
            name = "redis-conf"
            items {
              key = "redis.conf"
              path = "redis.conf"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "redis"
      managed-by  = "terraform"
    }
  }
  spec {
    selector = {
      app = "redis"
    }
    type = "NodePort"
    port {
      node_port   = 30200
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_config_map" "redis" {
  metadata {
    name = "redis-conf"
    namespace = "qa"
    labels = {
      app = "redis"
    }
  }
  data = {
    "redis.conf" = "${file("${path.module}/redis.conf")}"
  }
}

resource "kubernetes_persistent_volume_claim" "redis" {
  metadata {
    name = "redis-pvc"
    namespace = "qa"
    labels = {
      app = "redis"
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
