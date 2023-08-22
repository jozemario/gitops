terraform {
  #required_version = ">= 1.5.5"
  required_version = ">= 0.12.26"
}

 variable "subject" {
    type = string
    default = "tfctl-rc"
    description = "Subject to hello"
 }

variable "namespace" {
  value = "dev"
}

 output "hello_world" {
   value = "hey hey ya, ${var.subject}!"
 }

data "template_file" "chart_values" {
  template = file("./disabled/nfs-provider-k8s/chart-values.yml")
}
##helm install uol-nfs-provider --set nfs.server=34.216.204.56 --set nfs.path=/var/uolshare/ stable/nfs-client-provisioner

resource "helm_release" "nfs-provider" {
  chart = "nfs-subdir-external-provisioner/nfs-subdir-external-provisioner"
  name = "nfs-provider"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  #version   = "3.21.0"
  namespace = var.namespace

  values = [
    data.template_file.chart_values.rendered
  ]
}
