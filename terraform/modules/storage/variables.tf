variable "prefix" {
  description = "Naming prefix to all resources by this module"
  type = string
}

variable "location" {
  description = "Region to deploy into"
  type = string
}

variable "resource_group_name" {
  description = "Name of the RG, must already exist"
  type = string
}

variable "account_replication_type" {
  description = "Replication type for ST account: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS"
  type = string
  default = "LRS"
}

variable "access_tier" {
  description = "Access tier for the st account: Hot or Cool"
  type = string
  default = "Hot"
}

variable "containers" {
  description = "List of blob container names to create in ST"
  type = list(string)
  default = []
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed. Disabled by default, prefer private endpoints, VNet integration for production workloads"
  type = bool
  default = false
}

variable "identity_principal_ids_with_access" {
  description = "List of MI principal Ids to grant Storage Blob Data Contributor access. Leave empty if access will be wired up elsewhere"
  type = list(string)
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type = map(string)
  default = {}
}