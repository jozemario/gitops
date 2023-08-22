terraform {
  #required_version = ">= 1.5.5"
  required_version = ">= 0.12.26"
}

resource "kubernetes_namespace" "nfs-provider" {
  metadata {
    name = "dbs"
  }
}

 variable "subject" {
    type = string
    default = "tfctl-rc"
    description = "Subject to hello"
 }

variable "namespace" {
  value = "dbs"
}

 output "hello_world" {
   value = "hey hey ya, ${var.subject}!"
 }

data "template_file" "chart_values" {
  template = file("./disabled/nfs-provider-k8s/chart-values.yml")
}

resource "helm_release" "nfs-provider" {
  chart = "nfs-subdir-external-provisioner/nfs-subdir-external-provisioner"
  name = "nfs-provider"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  namespace = var.namespace

  values = [
    data.template_file.chart_values.rendered
  ]
}
