terraform {
  required_version = ">= 1.3.9"
}

variable "subject" {
   type = string
   default = "World"
   description = "Subject to hello"
}

output "hello_world" {
  value = "Hello TF Controller v0.16.0-rc.4, ${var.subject}!"
}