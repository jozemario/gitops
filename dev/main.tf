terraform {
  required_version = ">= 1.3.9"
}

variable "branch" {
   type = string
   default = "Environment"
   description = "Develop Branch"
}

output "environment" {
  value = "TF DEV Controller + Template v0.16.0-rc.2, ${var.branch}!"
}