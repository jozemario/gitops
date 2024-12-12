terraform {
  required_version = ">= 1.3.9"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "nginx"
      managed-by  = "terraform"
    }
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "MyTestApp"
      }
    }
    template {
      metadata {
        labels = {
          app = "MyTestApp"
        }
      }
      spec {
        container {
          image = "nginx"
          name  = "nginx-container"
          port {
            container_port = 80
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }

          volume_mount {
            name       = "nginx-pvc"
            sub_path   = "nginx"
            mount_path = "/usr/share/nginx/html"
          }
        }
        volume {
          name = "nginx-config"
          config_map {
            name = "nginx"
          }
        }

        volume {
          name = "nginx-pvc"
          persistent_volume_claim {
            claim_name = "nginx-pvc"
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "nginx"
      managed-by  = "terraform"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.nginx.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "qa"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-production"
      "kubernetes.io/ingress.class"    = "traefik"
    }
    labels = {
      app = "nginx"
    }
  }

  spec {
    rule {
      host = "isp.mghcloud.com"  # Change to your domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "nginx"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts = ["isp.mghcloud.com"]
      secret_name = "isp-mghcloud-com-tls"
    }
  }
}

resource "kubernetes_persistent_volume_claim" "nginx" {
  metadata {
    name      = "nginx-pvc"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "nginx"
      managed-by  = "terraform"
    }
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = "nfs"
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_config_map" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "nginx"
      managed-by  = "terraform"
    }
  }
  data = {
    "nginx.conf" = file("${path.module}/nginx.conf")
  }
}

