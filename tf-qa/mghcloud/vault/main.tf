terraform {
  required_version = ">= 1.3.9"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.16.1"
    }
  }
  
}

module "shared" {
  source = "../../shared"
}

data "template_file" "vault" {
	template =   file("${path.module}/chart-values.yml")
}

resource "kubernetes_secret" "vault-storage-config" {
  metadata {
    name      = "vault-storage-config"
    namespace = "qa"
  }
  data = {
    "config.hcl" = file("${path.module}/config.hcl")
  }
}

resource "helm_release" "vault" {
  chart = "vault"
  name = "vault"
  repository = "https://helm.releases.hashicorp.com/hashicorp"
  version   = "0.29.1"
  namespace = "qa"

  values = [
  	data.template_file.vault.rendered
  ]

  set {
    name = "server.service.dataStorage.storageClass"
    value = "nfs"
  }
  set {
    name = "server.service.dataStorage.size"
    value = "1Gi"
  } 

  set {
    name = "server.service.type"
    value = "NodePort"
  }

  set {
    name = "server.service.nodePort"
    value = "30300"
  }

  set {
    name = "server.volumes[0].name"
    value = "userconfig-vault-storage-config"
  }
  set {
    name = "server.volumes[0].secret.defaultMode"
    value = "420"
  }
  set {
    name = "server.volumes[0].secret.secretName"
    value = "vault-storage-config"
  }
  set {
    name = "server.volumeMounts[0].mountPath"
    value = "/vault/userconfig/vault-storage-config"
  }
  set {
    name = "server.volumeMounts[0].name"
    value = "userconfig-vault-storage-config"
  }
  set {
    name = "server.volumeMounts[0].readOnly"
    value = "true"
  }
  set {
    name = "server.extraArgs"
    value = "-config=/vault/userconfig/vault-storage-config/config.hcl"
  }

  set {
    name = "ui.enabled"
    value = "true"
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
      host = "vault.mghcloud.com"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = helm_release.vault.name
              port {
                number = 8200
              }
            }
          }
        }
      }
    }
    tls {
      hosts = ["vault.mghcloud.com"]
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
