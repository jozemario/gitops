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

resource "kubernetes_deployment" "minio" {
  metadata {
    name = "minio"
    namespace = "qa"
    labels = {
      app = "minio"
      managed-by = "terraform"
      environment = "qa"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "minio"
      }
    }
    template {
      metadata {
        labels = {
          app = "minio"
        }
      }
      spec {
        container {
          image = "minio/minio:latest"
          name = "minio-container"
          env {
            name = "MINIO_ROOT_USER"
            value = "minio"
          }
          env {
            name = "MINIO_ROOT_PASSWORD"
            value = "minio"
          }
          env {
            name = "MINIO_ACCESS_KEY"
            value = "minio"
          }
          env {
            name = "MINIO_SECRET_KEY"
            value = "minio"
          }

          volume_mount {
            name = "minio-data"
            mount_path = "/export"
            sub_path = "export"
          }
          volume_mount {
            name = "minio-config"
            mount_path = "/root/.minio"
            sub_path = ".minio"
          }

          port {
            name = "minio"
            container_port = 9000
          }
          port {
            name = "minio-console"
            container_port = 9001
          }
          command = ["/bin/sh", "-c"]
          args = ["minio server /export --console-address \":9001\""]

        }
        volume {
          name = "minio-data"
          persistent_volume_claim {
            claim_name = "minio-pvc"
          }
        }

        volume {
          name = "minio-config"
          persistent_volume_claim {
            claim_name = "minio-pvc"
          }
        }
        
        # volume {
        #   name = "minio-conf"
        #   config_map {
        #     name = "minio"
        #     items {
        #       key = ".minio"
        #       path = ".minio"
        #     }
        #     default_mode = "0755"
        #   }
        # }

        restart_policy = "Always"

      }
      
    }

  }
}

resource "kubernetes_service" "minio" {
  metadata {
    name = "minio"
    namespace = "qa"
    labels = {
      app = "minio"
    }
  }
  spec {
    selector = {
      app = "minio"
    }
    port {
      port = 9000
      target_port = 9000
      node_port = 30101
      name = "minio"
    }
    port {
      port = 9001
      target_port = 9001
      node_port = 30102
      name = "minio-console"
    }
    type = "NodePort"
  }
}

resource "kubernetes_persistent_volume_claim" "minio" {
  metadata {
    name = "minio-pvc"
    namespace = "qa"
    labels = {
      app = "minio"
      managed-by  = "terraform"
      environment = "qa"
    }
  }
  spec {
    storage_class_name = "nfs"
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_config_map" "minio" {
  metadata {
    name = "minio"
    namespace = "qa"
    labels = {
      app = "minio"
      managed-by  = "terraform"
      environment = "qa"
    }
  }
  data = {
    ".minio" = "${file("${path.module}/.minio")}"
  }
}