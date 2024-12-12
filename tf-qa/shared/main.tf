locals {
  config = {
      mariadb_password      = "change_me"
      mariadb_root_password = "change_me"
      mariadb_database      = "mghcloud"
      mariadb_user          = "mghcloud"
      wordpress_db_name     = "wordpress"
      wordpress_db_user     = "root"
      wordpress_db_password = "change_me"
      wordpress_db_host     = "201.205.178.45"
      wordpress_db_port     = "30005"
      postgres_database     = "postgres"
      postgres_user         = "mghcloud"
      postgres_password     = "change_me"
      

  }
}

output "config" {
  value = local.config
}