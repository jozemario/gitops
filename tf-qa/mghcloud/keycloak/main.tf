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

resource "kubernetes_deployment" "keycloak" {
  metadata {
    name = "keycloak"
    namespace = "qa"
    labels = {
      environment = "qa"
      app = "keycloak"
      managed-by = "terraform"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "keycloak"
      }
    }
    template {
      metadata {
        labels = {
          app = "keycloak"
          environment = "qa"
        }
      }
      spec {
        container {
          image = "quay.io/keycloak/keycloak:26.0.7"
          name = "keycloak-container"
          env {
            name = "KC_PROXY"
            value = "edge"
          }
          env {
            name = "KC_HOSTNAME"
            value = "https://keycloak.mghcloud.com"
          }
          env {
            name = "KC_BOOTSTRAP_ADMIN_USERNAME"
            value = module.shared.config.keycloak_user
          }
          env {
            name = "KC_BOOTSTRAP_ADMIN_PASSWORD"
            value = module.shared.config.keycloak_password
          }
          env {
            name = "KC_DB"
            value = "postgres"
          }
          env {
            name = "KC_DB_URL" # JDBC URL.
            value = "jdbc:postgresql://${module.shared.config.keycloak_db_host}:${module.shared.config.keycloak_db_port}/${module.shared.config.keycloak_database}"
          }

          env {
            name = "KC_DB_USERNAME"
            value = module.shared.config.keycloak_db_user
          }
          env {
            name = "KC_DB_PASSWORD"
            value = module.shared.config.keycloak_db_password
          }
          port {
            name = "http"
            container_port = 9080
          }
          port {
            name = "http2"
            container_port = 8080
          }
          port {
            name = "https"
            container_port = 8443
          }
          port {
            name = "httpsoc"
            container_port = 9990
          }
          # args = ["-b","0.0.0.0","-Dkeycloak.migration.action=import","-Dkeycloak.migration.provider=dir","-Dkeycloak.migration.dir=/opt/jboss/keycloak/realm-config","-Dkeycloak.migration.strategy=OVERWRITE_EXISTING"]#,"-Djboss.socket.binding.port-offset=1000"]

          volume_mount {
            mount_path = "/opt/jboss/keycloak/realm-config"
            name = "keycloak-pvc"
          }
        }
        volume {
          name = "keycloak-pvc"
          persistent_volume_claim {
            claim_name = "keycloak-pvc"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "keycloak" {
  metadata {
    name = "keycloak"
    namespace = "qa"
    labels = {
      environment = "qa"
      app = "keycloak"
      managed-by = "terraform"
    }
  }
  spec {
    selector = {
      app = "keycloak"
    }
    type = "NodePort"
    port {
      name = "http"
      node_port = 30205
      port = 9080
      target_port = 9080
    }
    port {
      name = "http2"
      node_port = 30206
      port = 8080
      target_port = 8080
    }
    port {
      name = "https"
      node_port = 30202
      port = 8443
      target_port = 8443
    }
    port {
      name = "httpsoc"
      node_port = 30203
      port = 9990
      target_port = 9990
    }
  }
}

resource "kubernetes_ingress_v1" "keycloak" {
  metadata {
    name = "keycloak"
    namespace = "qa"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-production"
      "kubernetes.io/ingress.class"    = "traefik"
    }
    labels = {
      app = "keycloak"
    }
  }
  spec {
    rule {
      host = "keycloak.mghcloud.com"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "keycloak"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    tls {
      hosts = ["keycloak.mghcloud.com"]
      secret_name = "keycloak-mghcloud-com-tls"
    }
  }
}

resource "kubernetes_persistent_volume_claim" "keycloak" {
  metadata {
    name = "keycloak-pvc"
    namespace = "qa"
    labels = {
      environment = "qa"
      app = "keycloak"
      managed-by = "terraform"
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