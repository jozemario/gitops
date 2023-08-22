terraform {
  required_version = ">= 1.5.5"
}

module "mssql-server-k8s" {
  source = "./mssql-server-k8s"
}
