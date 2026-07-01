variable "prefix" {
  description = "Naming applied to all resources"
  type = string
  default = "netmodtest"
}

variable "location" {
  description = "Region to deploy into"
  type = string
  default = "westeurope"
}

variable "subscription_id" {
  description = "Subscription ID"
  type = string
}

variable "my_ip" {
  description = "Current public IP, used for management access (SSH/RDP)"
  type = string
  default = "null"
}