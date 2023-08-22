data "template_file" "chart_values" {
  vars = {
    SERVER = "34.216.204.56"
    PATH = "/var/uolshare/"
  }
}

resource "helm_release" "nfs-provider" {
  chart = "nfs-subdir-external-provisioner/nfs-subdir-external-provisioner"
  name = "nfs-provider"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
}

set {
  name  = "nfs.server"
  value = data.template_file.chart_values.vars.SERVER
}

set {
  name  = "nfs.path"
  value = data.template_file.chart_values.vars.PATH
}
