terraform {
  required_version = ">= 1.3.9"
}

variable "subject" {
   type = string
   default = "Environment"
   description = "Welcome to Develop"
}

output "hello_world" {
  value = "Hello TF DEV Controller v0.16.0-rc.2, ${var.subject}!"
}