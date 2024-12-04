terraform {
  required_version = ">= 1.3.9"
}

variable "subject" {
   type = string
   default = "Branch Planner IaC"
   description = "Subject to hello"
}

output "hello_world" {
  value = "TF Controller v0.16.0-rc.4 with ${var.subject}!"
}