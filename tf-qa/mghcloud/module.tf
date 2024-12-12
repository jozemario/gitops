module "frontend" {
  source = "./frontend"
}

module "mariadb" {
  source = "./mariadb"
}

module "postgres" {
  source = "./postgres"
}