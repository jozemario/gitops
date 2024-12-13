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

resource "kubernetes_limit_range" "wordpress" {
  metadata {
    name      = "wordpress-limi-ranger"
    namespace = "qa"
  }
  spec {
    # limit {
    #   type = "Pod"
    #   max = {
    #     #cpu    = "200m"
    #     memory = "1024Mi"
    #   }
    # }
    # limit {
    #   type = "PersistentVolumeClaim"
    #   min = {
    #     storage = "24M"
    #   }
    # }
    limit {
      type = "Container"
      default = {
        #cpu    = "50m"
        memory = "1024Mi"
      }
      default_request = {
          memory = "512Mi"
      }
    }
  }
}


resource "kubernetes_deployment" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = "qa"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "wordpress"
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge = 0
        max_unavailable = 1
      }
    }
    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }
      spec {
        container {
          image = "wordpress:6.7.1-php8.1-fpm"
          name  = "wordpress-container"
          env {
            name  = "WORDPRESS_DB_HOST"
            value = "201.205.178.45:30005"
          }
          env {
            name = "WORDPRESS_DB_USER"
            value = "root"
          }
          env {
             name  = "WORDPRESS_DB_PASSWORD"
             value = "change_me"
           }
          env {
            name  = "WORDPRESS_DB_NAME"
            value = "wordpress"
          }
          /* env {
            name  = "PUID"
            value = "\\x31\\x30\\x33\\x35" # < ACII code for '1035'
          }
          env {
            name  = "TZ"
            value = "Europe/Amsterdam"
          } */
          /* security_context {
            privileged = true
            run_as_user = 0
          } */

          port {
            name = "http"
            container_port = 80
            protocol = "TCP"
          }
       
          volume_mount {
            mount_path = "/var/www/html"
            name = "wordpress-pvc"
            sub_path = "wordpress"
          }
          volume_mount {
            mount_path = "/usr/local/etc/php/conf.d/uploads.ini"
            name = "wordpress-conf"
            read_only = false
            sub_path = "uploads.ini"
          }

          
        }
        restart_policy = "Always"
        volume {
          name = "wordpress-pvc"
          persistent_volume_claim {
            claim_name = "wordpress-pvc"
          }
        }
        volume {
          name = "wordpress-conf"
          config_map {
            name = "wordpress"
            items {
              key = "uploads.ini"
              path = "uploads.ini"
            }
          }
          
        }
            
      }
    }
  }
}

resource "kubernetes_config_map" "wordpress" {
  metadata {
    name = "wordpress"
    labels = {
          app = "wordpress"
        }
    namespace = "qa"
  }
  data = {
    "uploads.ini" = "${file("${path.module}/uploads.ini")}"
  }

}

resource "kubernetes_service" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = "qa"
  }
  spec {
    selector = {
      app = "wordpress"
    }
    type = "NodePort"
    port {
      name        = "http"
      node_port   = 30222
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_persistent_volume_claim" "vitalk8s" {
  metadata {
    name      = "wordpress-pvc"
    labels = {
          app = "wordpress"
        }
    namespace = "qa"
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

resource "kubernetes_ingress_v1" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = "qa"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-production"
      "kubernetes.io/ingress.class"    = "traefik"
    }
    labels = {
      app = "wordpress"
    }
  }
  spec {
    rule {
      host = "wpsitelaw.mghcloud.com"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "wordpress"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    tls {
      hosts = ["wpsitelaw.mghcloud.com"]
      secret_name = "wpsitelaw-mghcloud-com-tls"
    }
  }
}
