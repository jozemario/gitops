data "template_file" "chart_values" {
  template = file("chart-values.yml")
}
##helm install uol-nfs-provider --set nfs.server=34.216.204.56 --set nfs.path=/var/uolshare/ stable/nfs-client-provisioner

resource "helm_release" "nfs-provider" {
  chart = "nfs-subdir-external-provisioner/nfs-subdir-external-provisioner"
  name = "nfs-provider"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  #version   = "3.21.0"
  #namespace = var.namespace

  values = [
    data.template_file.chart_values.rendered
  ]
}
