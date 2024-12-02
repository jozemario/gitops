terraform {
  required_version = ">= 1.3.9"
}

variable "branch" {
   type = string
   default = "qa"
   description = "QA Branch"
}

output "hello_world" {
  value = "Welcome to QA - ${var.branch} branch!"
}
