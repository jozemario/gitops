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

# resource "kubernetes_secret" "vault-secrets" {
#   metadata {
#     name      = "vault-secrets"
#     namespace = "qa"
#     labels = {
#       environment = "qa"
#       app         = "vault"
#       managed-by  = "terraform"
#     }
#   }

#   data = {
#     MYSQL_USER     = "root"
#     MYSQL_PASSWORD = "change-me"  # Replace with actual secret management
#     VAULT_TOKEN    = ""
#   }
# }

resource "kubernetes_deployment" "vault" {
  metadata {
    name      = "vault"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "vault"
      managed-by  = "terraform"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "vault"
      }
    }
    template {
      metadata {
        labels = {
          app = "vault"
        }
      }
      spec {
        init_container {
          name  = "vault-init"
          image = "vault:1.15.1"
        
        env {
          name  = "VAULT_ADDR"
          value = kubernetes_config_map.vault-env.data["VAULT_ADDR"]
        }
        env {
          name  = "MY_VAULT_TOKEN"
          value = "my-secure-token"
        #   value = kubernetes_secret.vault-secrets.data["VAULT_TOKEN"]
        }
        
        volume_mount {
          name       = "vault-init-script"
          mount_path = "/usr/local/bin/vault-init.sh"
          sub_path   = "vault-init.sh"
        }

        volume_mount {
            name       = "vault-pvc"
            mount_path = "/vault/file/vault-root-token"
            sub_path   = "vault-root-token"
        }

        volume_mount {
            name       = "vault-pvc"
            mount_path = "/vault/file"
            sub_path   = "data"
        }

        command = ["/usr/local/bin/vault-init.sh"]
        }


        container {     
          image = "vault:1.15.1"
          name  = "vault-container"
          port {
            container_port = 8200
          }

          env {
            name  = "VAULT_ADDR"
            value = "http://0.0.0.0:8200"
          }

          volume_mount {
            name       = "vault-config"
            mount_path = "/vault/config/config.hcl"
            sub_path   = "config.hcl"
          }

          volume_mount {
            name       = "vault-pvc"
            mount_path = "/vault/file"
            sub_path   = "data"
          }

          security_context {
            capabilities {
              add = ["IPC_LOCK"]
            }
          }
          command = ["server"]
        
        }

        restart_policy = "Always"

        volume {
          name = "vault-config"
          config_map {
            name = "vault-config"
          }
        }

        volume {
          name = "vault-pvc"
          persistent_volume_claim {
            claim_name = "vault-pvc"
          }
        }

        service_account_name = "vault"

        # security_context {
        #   run_as_non_root = true
        #   run_as_user     = 1000
        # }

        # termination_grace_period_seconds = 30


      }
    }
  }

}

resource "kubernetes_service" "vault" {
  metadata {
    name      = "vault"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "vault"
      managed-by  = "terraform"
    }
  }
  spec {
    selector = {
      app = "vault"
    }
    port {
      port        = 8200
      target_port = 8200
      protocol    = "TCP"
      name        = "vault"
      node_port   = 30300
    }
    
    port {
      port        = 8201
      target_port = 8201
      protocol    = "TCP"
      name        = "vault-cluster"
      node_port   = 30301
    }
  }

}

resource "kubernetes_ingress_v1" "vault" {
  metadata {
    name      = "vault"
    namespace = "qa"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-production"
      "kubernetes.io/ingress.class"    = "traefik"
    }
    labels = {
      app = "vault"
    }
  }
  spec {
    rule {
      host = kubernetes_config_map.vault-env.data["VAULT_DOMAIN"]
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.vault.metadata[0].name
              port {
                number = 8200
              }
            }
          }
        }
      }
    }
    tls {
      hosts = [kubernetes_config_map.vault-env.data["VAULT_DOMAIN"]]
      secret_name = "vault-mghcloud-com-tls"
    }
  }
}


resource "kubernetes_persistent_volume_claim" "vault" {
  metadata {
    name      = "vault-pvc"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "vault"
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


# resource "kubernetes_service_account" "vault" {
#   metadata {
#     name      = "vault"
#     namespace = "qa"
#   }
#   automount_service_account_token = true
#   secret {
#     name = "vault-secrets"
#   }
#   depends_on = [kubernetes_secret.vault-secrets]

# }       



resource "kubernetes_config_map" "vault-config" {
  metadata {
    name      = "vault-config"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "vault"
      managed-by  = "terraform"
    }
  }
  data = {
    "config.hcl" = file("${path.module}/config.hcl")
  }
}   

resource "kubernetes_config_map" "vault-env" {
  metadata {
    name      = "vault-env"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "vault"
      managed-by  = "terraform"
    }
  }

  data = {
    VAULT_DOMAIN       = "vault.mghcloud.com"
    VAULT_API_ADDR     = "http://201.205.178.45:30300"
    VAULT_CLUSTER_ADDR = "http://201.205.178.45:30301"
    VAULT_ADDR         = "http://201.205.178.45:30300"
    MYSQL_HOST         = "201.205.178.45"
    MYSQL_PORT         = "30005"
    MYSQL_DATABASE     = "vaultdb"
  }
}
