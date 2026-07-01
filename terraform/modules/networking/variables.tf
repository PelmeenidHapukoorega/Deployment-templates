variable "prefix" {
  description = "Naming prefix to all resources created by this module"
  type = string
}

variable "location" {
  description = "AZ region to deploy into"
  type = string
}

variable "resource_group_name" {
  description = "RG group name to deploy into, must already exist"
  type = string
}

variable "vnet_address_space" {
  description = "VNet address space"
  type = list(string)
  default = [ "10.0.0.0/16" ]
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name = string
    address_prefixes = list(string)
  }))
  default = [
    {
        name = "default"
        address_prefixes = [ "10.0.1.0/24" ]
    }
  ]
}

variable "enable_http" {
  description = "Allow inbound HTTP from any source"
  type = bool
  default = false
}

variable "enable_https" {
  description = "Allow inbound HTTPS from any source"
  type = bool
  default = false
}

variable "management_allowed_cidr" {
  description = "CIDR allowed to access management ports (SSH/RDP). Has to be specific IP (/32), not a range. Leave null to disable mg access entirely"
  type = string
  default = "null"

  validation {
    condition = var.management_allowed_cidr == null || can(regex("/32$", var.management_allowed_cidr))
    error_message = "management_allowed_cidr must be a single IP with /32 suffix, not range. Open management access to range is security risk"
  }
}

variable "management_ports" {
  description = "MG ports to open if management_allowed_cidr is set"
  type = list(number)
  default = [ 22, 3389 ]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type = map(string)
  default = {}
}