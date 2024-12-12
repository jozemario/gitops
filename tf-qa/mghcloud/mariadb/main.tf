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

resource "kubernetes_deployment" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "mariadb"
      managed-by  = "terraform"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mariadb"
      }
    }
    template {
      metadata {
        labels = {
          app = "mariadb"
        }
      }
      spec {
        container {
          image = "mariadb:10.5.4-focal"
          name  = "mariadb-container"
          env {
            name  = "MYSQL_DATABASE"
            value = module.shared.config.mariadb_database
          }
          env {
            name  = "MYSQL_USER"
            value = module.shared.config.mariadb_user
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = module.shared.config.mariadb_password
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = module.shared.config.mariadb_root_password
          }

          port {
            name = "mariadb"
            container_port = 3306
          }

          volume_mount {
            mount_path = "/var/lib/mysql"
            sub_path   = "mysql"
            name = "mariadb-pvc"
          }

          volume_mount {
            mount_path = "/etc/mysql/conf.d/my.cnf"
            name = "mariadb-config"
            sub_path = "my.cnf"
          }

          volume_mount {
            mount_path = "/docker-entrypoint-initdb.d"
            name       = "mariadb-init"
          }

        }
        volume {
          name = "mariadb-pvc"
          persistent_volume_claim {
            claim_name = "mariadb-pvc"
          }
        }

        volume {
          name = "mariadb-config"
          config_map {
            name = "mariadb"
          }
        }

        volume {
          name = "mariadb-init"
          config_map {
            name = "mariadb"
            items {
              key = "init.sql"
              path = "init.sql"
            }
          }
        }

      }
    }
  }
}

resource "kubernetes_service" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "mariadb"
      managed-by  = "terraform"
    }
  }
  spec {
    selector = {
      app = "mariadb"
    }
    type = "NodePort"
    port {
      name        = "mariadb"
      node_port   = 30005
      port        = 3306
      target_port = 3306
    }
  }
}

resource "kubernetes_config_map" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "mariadb"
      managed-by  = "terraform"
    }
  }
  data = {
    "my.cnf" = file("${path.module}/my.cnf")
    "init.sql" = <<-EOF
      USE mysql;
      FLUSH PRIVILEGES;
      ALTER USER 'root'@'localhost' IDENTIFIED BY '${module.shared.config.mariadb_root_password}';
      CREATE USER 'root'@'%' IDENTIFIED BY '${module.shared.config.mariadb_root_password}';
      GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
      CREATE USER '${module.shared.config.mariadb_user}'@'%' IDENTIFIED BY '${module.shared.config.mariadb_password}';
      GRANT ALL PRIVILEGES ON ${module.shared.config.mariadb_database}.* TO '${module.shared.config.mariadb_user}'@'%';
      FLUSH PRIVILEGES;
    EOF
  }
}

resource "kubernetes_persistent_volume_claim" "mariadb" {
  metadata {
    name      = "mariadb-pvc"
    namespace = "qa"
    labels = {
      environment = "qa"
      app         = "mariadb"
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


