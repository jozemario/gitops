#terraform {
#  required_version = ">= 1.5.5"
#}
#
# variable "subject" {
#    type = string
#    default = "tfctl-rc"
#    description = "Subject to hello"
# }
#
# output "hello_world" {
#   value = "hey hey ya, ${var.subject}!"
# }
data "template_file" "chart_values" {
	template = file("./mssql-server-k8s/chart-values.yml")
}

resource "helm_release" "mssql-server" {
  chart = "cloudnativeapp/mssql-linux"
  name = "mssql-server"
  repository = "https://cloudnativeapp.github.io/charts/curated/"
  version   = "0.7.0"
  namespace = "dev"

  values = [
  	data.template_file.chart_values.rendered
  ]
}
