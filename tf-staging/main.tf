terraform {
  required_version = ">= 1.3.9"
}

variable "branch" {
   type = string
   default = "develop"
   description = "Staging Branch"
}

output "environment" {
  value = "Welcome to Staging - ${var.branch} branch!"
}