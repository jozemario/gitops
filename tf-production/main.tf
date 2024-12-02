terraform {
  required_version = ">= 1.3.9"
}

variable "branch" {
   type = string
   default = "main"
   description = "Production Branch"
}

output "environment" {
  value = "Welcome to Production - ${var.branch} branch!"
}
