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
   default = "QA"
   description = "QA Branch"
}

output "hello_world" {
  value = "Welcome to ENV - ${var.branch}!"
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "qa"
  }
  spec {
    replicas = 2
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
        }
      }
    }
  }
}
resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "qa"
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