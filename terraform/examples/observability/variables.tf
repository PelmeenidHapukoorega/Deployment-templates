variable "prefix" {
  type = string
  default = "obsmodtest"
}

variable "location" {
  type = string
  default = "westeurope"
}

variable "subscription_id" {
  type = string
}

variable "my_ip" {
  type = string
  default = ""
}

variable "alert_email" {
  type = string
  default = ""
}

variable "ssh_public_key" {
  description = "Ssh public key for test vms admin"
  type = string
}