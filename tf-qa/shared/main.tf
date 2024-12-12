locals {
  config = {
      mariadb_password      = "change_me"
      mariadb_root_password = "change_me"
      mariadb_database      = "mghcloud"
      mariadb_user          = "mghcloud"
  }
}

output "config" {
  value = local.config
}