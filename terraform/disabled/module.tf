terraform {
  required_version = ">= 0.15.1"
}

#module "nfs-provider-k8s" {
#  source = "./nfs-provider-k8s"
#}

module "mssql-server-k8s" {
  source = "./mssql-server-k8s"
}
