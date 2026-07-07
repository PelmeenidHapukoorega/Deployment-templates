variable "prefix" {
  description = "Naming prefix for all resources created by this module"
  type = string
}

variable "location" {
  description = "Region to deploy into"
  type = string
}

variable "resource_group_name" {
  description = "Name of RG, must exist"
  type = string
}

variable "enable_key_vault" {
  description = "Create key vault alongside managed identity, only enable when non AZ secrets need storing. Managed identity for AZ to AZ auth preferred"
  type = bool
  default = false
}

variable "key_vault_sku" {
  description = "SKU for key vault, if created (optional)"
  type = string
  default = "standard"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type = map(string)
  default = {}
}
