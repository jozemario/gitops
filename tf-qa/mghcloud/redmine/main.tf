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

resource "kubernetes_deployment" "redmine" {
  metadata {
    name      = "redmine"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "redmine"
      managed-by  = "terraform"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "redmine"
      }
    }
    template {
      metadata {
        labels = {
          app = "redmine"
        }
      }
      spec {
        container {
          name = "redmine-container"
          image = "redmine:6.0.2"
          env {
            name = "REDMINE_SECRET_KEY_BASE"
            value = module.shared.config.redmine_secret_key_base
          }
          env {
            name = "REDMINE_DB_USERNAME"
            value = "root"
          }
          env {
            name = "REDMINE_DB_PASSWORD"
            value = "change_me"
          }
          env {
            name = "REDMINE_DB_DATABASE"
            value = "redmine"
          }
          env {
            name = "REDMINE_DB_PORT"
            value = "30005"
          }
          env {
            name = "REDMINE_DB_MYSQL"
            value = "201.205.178.45"
          }
          port {
            name = "redmine"
            container_port = 3000
          }
          volume_mount {
            name = "redmine-pvc"
            mount_path = "/usr/src/redmine/files"
            sub_path = "files"
          }
          volume_mount {
            name = "redmine-pvc"
            mount_path = "/usr/src/redmine/plugins"
            sub_path = "plugins"
          }
          volume_mount {
            name = "redmine-pvc"
            mount_path = "/root/.ssh"
            sub_path = ".ssh"
          }
          volume_mount {
            name = "redmine-pvc"
            mount_path = "/usr/src/redmine/public/themes"
            sub_path = "themes"
          }
          volume_mount {
            name = "redmine-pvc"
            mount_path = "/usr/src/redmine/vendor/plugins"
            sub_path = "vendor"
          }
          volume_mount {
            name = "redmine-pvc"
            mount_path = "/usr/src/redmine/public/assets"
            sub_path = "assets"
          }
        #   volume_mount {
        #     name = "redmine-pvc"
        #     mount_path = "/usr/src/redmine/config"
        #     sub_path = "config"
        #     read_only = false
        #   }
          volume_mount {
            name = "redmine-conf"
            mount_path = "/etc/redmine/database.yml"
            sub_path = "database.yml"
            read_only = false
          }
          volume_mount {
            name = "redmine-conf"
            mount_path = "/etc/redmine/configuration.yml"
            sub_path = "configuration.yml"
            read_only = false
          }

          volume_mount {
            name = "redmine-conf"
            mount_path = "/etc/redmine/secrets.yml"
            sub_path = "secrets.yml"
            read_only = false
          }
          volume_mount {
            name = "redmine-pvc"
            mount_path = "/usr/src/redmine/repos"
            sub_path = "repos"
          }
          volume_mount {
            name = "redmine-pvc"
            mount_path = "/git"
            sub_path = "git"
          }

          lifecycle {
            post_start {
              exec {
                # copy database.yml  to /usr/src/redmine/config/database.yml and 
                # copy configuration.yml to /usr/src/redmine/config/configuration.yml
                # copy secrets.yml to /usr/src/redmine/config/secrets.yml
                # generate secret_key_base https://qiita.com/ssugimoto/items/c2b90c0b745f15575a71
                command = ["/bin/sh", "-c", "cp -v /etc/redmine/database.yml /usr/src/redmine/config/database.yml && cp -v /etc/redmine/configuration.yml /usr/src/redmine/config/configuration.yml && cp -v /etc/redmine/secrets.yml /usr/src/redmine/config/secrets.yml && bundle exec rake generate_secret_token"]
              }
            }
          }
        }

        volume {
          name = "redmine-pvc"
          persistent_volume_claim {
            claim_name = "redmine-pvc"
          }
        }
        volume {
          name = "redmine-conf"
          config_map {
            name = "redmine"
            items {
              key = "configuration.yml"
              path = "configuration.yml"
            }
            items {
              key = "database.yml"
              path = "database.yml"
            }
            items {
              key = "secrets.yml"
              path = "secrets.yml"
            }
            default_mode = "0755"
          }
        }
      }
    }
  }

}

resource "kubernetes_service" "redmine" {
  metadata {
    name      = "redmine"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "redmine"
      managed-by  = "terraform"
    }
  }
  spec {
    selector = {
      app = "redmine"
    }
    type = "NodePort"
    port {
      name = "redmine"
      node_port = 30012
      port = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_persistent_volume_claim" "redmine" {
  metadata {
    name = "redmine-pvc"
    namespace = "qa"
    labels = {
      app = "redmine"
      managed-by  = "terraform"
      environment = "qa"
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

resource "kubernetes_config_map" "redmine" {
  metadata {
    name = "redmine"
    namespace = "qa"
    labels = {
      app = "redmine"
    }
  }
  data = {
    "configuration.yml" = "${file("${path.module}/configuration.yml")}"
    "database.yml" = "${file("${path.module}/database.yml")}"
    "secrets.yml" = "${file("${path.module}/secrets.yml")}"
  }
}


resource "kubernetes_ingress_v1" "redmine" {
  metadata {
    name = "redmine"
    namespace = "qa"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-production"
      "kubernetes.io/ingress.class"    = "traefik"
    }
    labels = {
      app = "redmine"
    }
  }
  spec {
    rule {
      host = "redmine.mghcloud.com"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "redmine"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
    tls {
      hosts = ["redmine.mghcloud.com"]
      secret_name = "redmine-mghcloud-com-tls"
    }
  }
}