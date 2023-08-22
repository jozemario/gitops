terraform {
  #required_version = ">= 1.5.5"
  required_version = ">= 0.15.1"
}

 variable "subject" {
    type = string
    default = "tfctl-rc"
    description = "Subject to hello"
 }

 output "hello_world" {
   value = "hey hey ya, ${var.subject}!"
 }
