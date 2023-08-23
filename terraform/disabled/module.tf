terraform {
  #required_version = ">= 1.5.5"
  required_version = ">= 0.15.1"
}

module "mariadb10k8s" {
  source = "./mariadb10k8s"
}
