terraform {
  required_version = ">= 1.3.9"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }

    # helm = {
    #   source  = "hashicorp/helm"
    #   version = ">= 2.16.1"
    # }
  }
  
}

module "shared" {
  source = "../../shared"
}

# data "template_file" "vault" {
# 	template =   file("${path.module}/chart-values.yml")
# }

# resource "kubernetes_secret" "vault-storage-config" {
#   metadata {
#     name      = "vault-storage-config"
#     namespace = "qa"
#   }
#   data = {
#     "config.hcl" = file("${path.module}/config.hcl")
#   }
# }

resource "kubernetes_config_map" "vault" {
  metadata {
    name      = "vault"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "vault"
      managed-by  = "terraform"
    }
  }
  data = {
    "config.hcl" = file("${path.module}/config.hcl")
    "vault-init.sh" = file("${path.module}/vault-init.sh")
  }
}

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
        container {
          image = "hashicorp/vault:1.18.2"
          name = "vault-container"
          env {
            name = "VAULT_ADDR"
            value = "http://0.0.0.0:8200"
          }
          port {
            container_port = 8200
          }
          volume_mount {
            mount_path = "/vault/config/config.hcl"
            name = "vault-config"
            sub_path = "config.hcl"
            read_only = false
          }
          volume_mount {
            mount_path = "/vault/file/"
            name = "vault-pvc"
            sub_path = "vault"
            read_only = false
          }
          volume_mount {
            mount_path = "/usr/local/bin/vault-init.sh"
            name = "vault-init"
            sub_path = "vault-init.sh"
            read_only = false
          }

          lifecycle {
            post_start {
              exec {
                command = ["/bin/sh", "-c", "chmod +x /usr/local/bin/vault-init.sh && /usr/local/bin/vault-init.sh"]
              }
            }
          }

          security_context {
            capabilities {
              add = ["IPC_LOCK"]
            }
          }

          command = ["/bin/sh", "-c"]
          args = ["vault server -config=/vault/config/config.hcl"]

        }
        # init_container {
        #   image = "hashicorp/vault:1.18.2"
        #   name = "vault-init"
        #   env {
        #     name = "VAULT_ADDR"
        #     value = "http://201.205.178.45:30300"
        #   }
        #   env {
        #     name = "MY_VAULT_TOKEN"
        #     value = "my-secure-token"
        #   }
        #   volume_mount {
        #     mount_path = "/vault/file/"
        #     name = "vault-pvc"
        #     sub_path = "vault"
        #     read_only = false
        #   }
        #   volume_mount {
        #     mount_path = "/vault/file/vault-root-token"
        #     name = "vault-pvc"
        #     sub_path = "vault-root-token"
        #     read_only = false
        #   }
        #   volume_mount {
        #     mount_path = "/usr/local/bin/vault-init.sh"
        #     name = "vault-init"
        #     sub_path = "vault-init.sh"
        #     read_only = false
        #   }
        #   command = ["/bin/sh", "-c"]
        #   args = ["chmod +x /usr/local/bin/vault-init.sh && /usr/local/bin/vault-init.sh"]
          
        # }
        
        restart_policy = "Always"
        volume {
          name = "vault-config"
          config_map {
            name = "vault"
          }
        }

        volume {
          name = "vault-pvc"
          persistent_volume_claim {
            claim_name = "vault-pvc"
          }
        } 

        volume {
          name = "vault-init"
          config_map {
            name = "vault"
            items {
              key = "vault-init.sh"
              path = "vault-init.sh"
            }
            default_mode = "0755"  # This makes the script executable

          }
        }

        # service_account_name = "vault"
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
    type = "NodePort"
    port {
      name = "vault"
      node_port = 30300
      port = 8200
      target_port = 8200
    }
  }
}



# resource "helm_release" "vault" {
#   chart = "hashicorp/vault"
#   name = "vault"
#   repository = "https://helm.releases.hashicorp.com"
#   version   = "0.29.1"
#   namespace = "qa"

#   values = [
#   	data.template_file.vault.rendered
#   ]

#   set {
#     name = "server.service.dataStorage.storageClass"
#     value = "nfs"
#   }
#   set {
#     name = "server.service.dataStorage.size"
#     value = "1Gi"
#   } 

#   set {
#     name = "server.service.type"
#     value = "NodePort"
#   }

#   set {
#     name = "server.service.nodePort"
#     value = "30300"
#   }

#   set {
#     name = "server.volumes[0].name"
#     value = "userconfig-vault-storage-config"
#   }
#   set {
#     name = "server.volumes[0].secret.defaultMode"
#     value = "420"
#   }
#   set {
#     name = "server.volumes[0].secret.secretName"
#     value = "vault-storage-config"
#   }
#   set {
#     name = "server.volumeMounts[0].mountPath"
#     value = "/vault/userconfig/vault-storage-config"
#   }
#   set {
#     name = "server.volumeMounts[0].name"
#     value = "userconfig-vault-storage-config"
#   }
#   set {
#     name = "server.volumeMounts[0].readOnly"
#     value = "true"
#   }
#   set {
#     name = "server.extraArgs"
#     value = "-config=/vault/userconfig/vault-storage-config/config.hcl"
#   }

#   set {
#     name = "ui.enabled"
#     value = "true"
#   }
    
# }

# resource "kubernetes_ingress_v1" "vault" {
#   metadata {
#     name      = "vault"
#     namespace = "qa"
#     annotations = {
#       "cert-manager.io/cluster-issuer" = "letsencrypt-production"
#       "kubernetes.io/ingress.class"    = "traefik"
#     }
#     labels = {
#       app = "vault"
#     }
#   }
#   spec {
#     rule {
#       host = "vault.mghcloud.com"
#       http {
#         path {
#           path = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "vault"
#               port {
#                 number = 8200
#               }
#             }
#           }
#         }
#       }
#     }
#     tls {
#       hosts = ["vault.mghcloud.com"]
#       secret_name = "vault-mghcloud-com-tls"
#     }
#   }
# }


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
