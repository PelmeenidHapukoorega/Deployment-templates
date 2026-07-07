variable "prefix" {
  description = "Naming prefix for all resources"
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

variable "retention_in_days" {
  description = "Retention period in days"
  type = number
  default = 30
}

variable "sku" {
  description = "SKU for log analytics workspace"
  type = string
  default = "PerGB2018"
}

variable "diagnostic_targets" {
  description = "List of resource IDs to send diagnostic logs to the workspace"
  type = list(string)
  default = []
}

variable "alert_email" {
  description = "Email for alert notifications. Optional"
  type = string
  default = ""
}

variable "alert_targets" {
  description = "List of resource Ids to create CPU/memory alerts against"
  type = list(string)
  default = []
}

variable "enable_cpu_alert" {
  description = "CPU alert for each alert target"
  type = bool
  default = true
}

variable "enable_memory_alert" {
  description = "Memory alert for each alert target"
  type = bool
  default = true
}

variable "cpu_threshold" {
  description = "CPU % threshold that triggers the alert"
  type = number
  default = 80
}

variable "memory_threshold" {
  description = "Memory threshold in bytes that triggers the alert."
  type = number
  default = 500000000
}

variable "tags" {
  description = "Tags for all resources"
  type = map(string)
  default = {}
}

variable "enable_log_category" {
  description = "Optional to include log category grouping. VMs are not supported. Set to false when targeting VMs"
  type = bool
  default = true
}