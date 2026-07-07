# Observability Module

Reusable Terraform module for deploying a Log Analytics workspace, optional diagnostic settings, and optional metric alerts with email notification via an action group.

Built to standardise the observability setup repeated across Lab 06 and earlier projects: one workspace, wired up to whatever resources you point it at, with sensible alert defaults out of the box.

## Design philosophy

**The Log Analytics workspace is always created** : its the foundation everything else attaches to.

**Diagnostic settings and alerts are opt-in via target lists**, not automatic. This module doesnt create its own resources to monitor, it accepts `diagnostic_targets` and `alert_targets` as lists of resource IDs supplied by the caller following the same composition pattern as the security and storage modules.

**Alerts and the action group share one activation condition.** Both are gated on `alert_email` being non-empty. If left empty, no action group and no alerts are created, just the workspace and any diagnostic settings. This keeps the two resources from drifting out of sync, since alerts reference the action group directly and would fail if it didnt exist.

**Not all resource types support log category grouping.** Diagnostic settings' `enabled_log` with `category_group = "allLogs"` works for resource types like Storage, Key Vault, and App Service, but Azure rejects it for Virtual Machines. Use `enable_log_category = false` when targeting VMs; metrics will still flow correctly regardless of this setting.

**Memory alerts use raw bytes, not percentage.** Azure Monitors `Available Memory Bytes` metric is measured in bytes, the default threshold (`500000000`, ~500MB) reflects that. CPU alerts use percentage, matching Azures `Percentage CPU` metric.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `prefix` | string | — | Naming prefix applied to all resources |
| `location` | string | — | Azure region to deploy into |
| `resource_group_name` | string | — | Name of an existing resource group to deploy into |
| `retention_in_days` | number | `30` | Log retention period |
| `sku` | string | `"PerGB2018"` | SKU for the Log Analytics workspace |
| `diagnostic_targets` | list(string) | `[]` | Resource IDs to send diagnostic logs/metrics to this workspace |
| `enable_log_category` | bool | `true` | Include log category grouping in diagnostic settings — set `false` for VM targets |
| `alert_email` | string | `""` | Email for alert notifications. Leave empty to skip creating the action group and alerts entirely |
| `alert_targets` | list(string) | `[]` | Resource IDs to create CPU/memory alerts against |
| `enable_cpu_alert` | bool | `true` | Create a CPU alert for each alert target |
| `enable_memory_alert` | bool | `true` | Create a memory alert for each alert target |
| `cpu_threshold` | number | `80` | CPU percentage that triggers the alert |
| `memory_threshold` | number | `500000000` | Available memory in bytes below which the alert triggers (~500MB) |
| `tags` | map(string) | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `workspace_id` | Resource ID of the Log Analytics workspace |
| `workspace_name` | Name of the Log Analytics workspace |
| `workspace_customer_id` | Workspace (customer) ID, used by agents/apps that ingest logs directly |
| `action_group_id` | Resource ID of the action group, or `null` if `alert_email` was not provided |

## Usage

```hcl
resource "azurerm_resource_group" "this" {
  name     = "myproject-rg"
  location = "westeurope"
}

resource "azurerm_linux_virtual_machine" "app" {
  # ... VM config ...
}

module "observability" {
  source = "../../modules/observability"

  prefix               = "myproject"
  location             = "westeurope"
  resource_group_name  = azurerm_resource_group.this.name

  diagnostic_targets   = [azurerm_linux_virtual_machine.app.id]
  enable_log_category  = false  # VMs don't support log category grouping

  alert_targets = [azurerm_linux_virtual_machine.app.id]
  alert_email   = "you@example.com"

  cpu_threshold    = 80
  memory_threshold = 500000000  # ~500MB

  tags = {
    Environment = "Production"
  }
}
```

**For resource types that support log categories** (Storage, Key Vault, App Service), omit `enable_log_category` or set it to `true` (the default) to capture both logs and metrics.

See [`examples/observability`](../../examples/observability/) for a complete, deployable example that provisions a test VM and wires up full observability against it.