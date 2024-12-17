module "frontend" {
  source = "./frontend"
}

module "postgres" {
  source = "./postgres"
}

module "mariadb" {
  source = "./mariadb"
}

module "wordpress" {
  source = "./wordpress"
}

# module "vault" {
#   source = "./vault"
# }

# module "keycloak" {
#   source = "./keycloak"
# }