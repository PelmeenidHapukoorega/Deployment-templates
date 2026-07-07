resource "azurerm_log_analytics_workspace" "this" {
  name = "${var.prefix}-law"
  location = var.location
  resource_group_name = var.resource_group_name
  sku = var.sku
  retention_in_days = var.retention_in_days
  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = { for idx, target in var.diagnostic_targets : tostring(idx) => target }

  name = "${var.prefix}-diag-${each.key}"
  target_resource_id = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "enabled_log" {
    for_each = var.enable_log_category ? [1] : []
    content {
      category_group = "allLogs"
    }
  }
  
  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_action_group" "this" {
  count = var.alert_email != "" ? 1 : 0

  name = "${var.prefix}-action-group"
  resource_group_name = var.resource_group_name
  short_name = substr("${var.prefix}ag", 0, 12)
  tags = var.tags

  email_receiver {
    name = "primary"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  for_each = var.enable_cpu_alert && var.alert_email != "" ? { for idx, target in var.alert_targets : tostring(idx) => target } : {}

  name = "${var.prefix}-cpu-alert-${each.key}"
  resource_group_name = var.resource_group_name
  scopes = [each.value]
  description = "Alert when CPU exceeds ${var.cpu_threshold}%"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name = "Percentage CPU"
    aggregation = "Average"
    operator = "GreaterThan"
    threshold = var.cpu_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.this[0].id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "memory" {
  for_each = var.enable_memory_alert && var.alert_email != "" ? { for idx, target in var.alert_targets : tostring(idx) => target } : {}

  name = "${var.prefix}-memory-alert-${each.key}"
  resource_group_name = var.resource_group_name
  scopes = [each.value]
  description = "Alert when memory drops below threshold"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name = "Available memory bytes"
    aggregation = "Average"
    operator = "LessThan"
    threshold = var.memory_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.this[0].id
  }

  tags = var.tags
}
