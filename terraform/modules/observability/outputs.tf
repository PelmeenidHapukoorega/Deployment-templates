output "workspace_id" {
  description = "Resource ID of the log analytics workspace"
  value = azurerm_log_analytics_workspace.this.id
}

output "workspace_name" {
  description = "Name of the workspace"
  value = azurerm_log_analytics_workspace.this.name
}

output "workspace_customer_id" {
  description = "Workspace (customer) id, used by agents and apps to send logs directly"
  value = azurerm_log_analytics_workspace.this.workspace_id
}

output "action_group_id" {
  description = "Resource ID of the action group, null if not created"
  value = var.alert_email != "" ? azurerm_monitor_action_group.this[0].id : null
}