module "shared" {
  source = "../shared"
}

module "frontend" {
  source = "./frontend"
}

module "mariadb" {
  source = "./mariadb"
}
