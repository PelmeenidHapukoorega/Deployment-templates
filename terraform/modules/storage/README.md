# Storage Module

Reusable Terraform module for deploying an Azure Storage Account with configurable redundancy, optional blob containers, and identity-based access control.

No keys or connection strings are ever exposed by this module. Access is granted exclusively through RBAC role assignments to managed identity principal IDs supplied by the caller: consistent with the identity-first philosophy used throughout this module library.

## Design philosophy

**No key-based access, structurally.** This module never outputs a storage account key or connection string. The only way to grant access is via `identity_principal_ids_with_access`, which assigns `Storage Blob Data Contributor` to whichever managed identity principal IDs are supplied.

**Secure by default.** `public_network_access_enabled` defaults to `false`. HTTPS-only traffic and TLS 1.2 minimum are enforced unconditionally, not configurable off.

**Composition over built-in identity creation.** This module does not create its own managed identity. If you need one, create it with the [security module](../security/) and pass its `identity_principal_id` output into this module's `identity_principal_ids_with_access` list. Each module owns one responsibility; composition happens at the calling layer.

**Cost-conscious defaults.** `account_replication_type` defaults to `LRS` : the cheapest option. Opt into `ZRS` or `GRS` explicitly when redundancy is actually required for the workload.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `prefix` | string | — | Naming prefix applied to all resources |
| `location` | string | — | Azure region to deploy into |
| `resource_group_name` | string | — | Name of an existing resource group to deploy into |
| `account_replication_type` | string | `"LRS"` | Replication type: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS |
| `access_tier` | string | `"Hot"` | Access tier: Hot or Cool |
| `containers` | list(string) | `[]` | Blob container names to create |
| `public_network_access_enabled` | bool | `false` | Whether public network access is allowed |
| `identity_principal_ids_with_access` | list(string) | `[]` | Managed identity principal IDs to grant `Storage Blob Data Contributor` |
| `tags` | map(string) | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `storage_account_id` | Resource ID of the storage account |
| `storage_account_name` | Name of the storage account |
| `primary_blob_endpoint` | Primary blob service endpoint URL |
| `container_ids` | Map of container name to container resource ID |

**Note:** no key or connection string outputs exist. Use `identity_principal_ids_with_access` for access instead.

## Usage

```hcl
resource "azurerm_resource_group" "this" {
  name     = "myproject-rg"
  location = "westeurope"
}

module "security" {
  source = "../../modules/security"

  prefix               = "myproject"
  location             = "westeurope"
  resource_group_name  = azurerm_resource_group.this.name
}

module "storage" {
  source = "../../modules/storage"

  prefix               = "myproject"
  location             = "westeurope"
  resource_group_name  = azurerm_resource_group.this.name

  account_replication_type = "ZRS"
  containers               = ["uploads", "logs"]

  identity_principal_ids_with_access = [
    module.security.identity_principal_id
  ]

  tags = {
    Environment = "Production"
  }
}
```

This composes the security module (for the identity) with the storage module (for the account), granting the identity blob access: no keys involved.

See [`examples/storage`](../../examples/storage/) for a complete, deployable example.