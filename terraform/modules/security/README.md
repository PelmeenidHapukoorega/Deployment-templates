# Security Baseline Module

Reusable Terraform module for deploying a user-assigned managed identity as the primary building block for identity-based authentication, with an optional Key Vault for the residual secrets that cant use managed identity.

Built around the principle that Azure-to-Azure authentication should use managed identities wherever possible, avoiding the chicken and egg problem of needing a stored credential to fetch other credentials. KV exists here only as a fallback for what genuinely requires it: third-party API

## Design philosophy

**The managed identity is the primary deliverable of this module, always created.** It can be attached to VMs, AKS clusters, App Services, or any Azure resource that supports user-assigned identities, enabling passwordless authentication to other Azure services.

**Key Vault is optional and secondary**, created only when `enable_key_vault = true`. It should be reserved for secrets that genuinely cant be avoided: non-Azure API keys, certificates, connection strings for external systems. For anything Azure-to-Azure, prefer wiring up the managed identity directly rather than routing through KV.

**When Key Vault is created:**
- RBAC authorization mode (not legacy access policies)
- Soft delete enabled, 7-day retention
- Purge protection enabled
- The managed identity is automatically granted `Key Vault Secrets User` on it: read-only, least privilege

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `prefix` | string | — | Naming prefix applied to all resources |
| `location` | string | — | Azure region to deploy into |
| `resource_group_name` | string | — | Name of an existing resource group to deploy into |
| `enable_key_vault` | bool | `false` | Create a Key Vault alongside the managed identity |
| `key_vault_sku` | string | `"standard"` | SKU for the Key Vault, if created |
| `tags` | map(string) | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `identity_id` | Resource ID of the managed identity: use to manage/attach the identity as an Azure resource |
| `identity_principal_id` | Principal ID of the identity: use when granting it RBAC roles on other resources |
| `identity_client_id` | Client ID of the identity:  use in application code to request tokens |
| `key_vault_id` | Resource ID of the Key Vault, or `null` if not created |
| `key_vault_uri` | URI of the Key Vault, or `null` if not created |

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

  enable_key_vault = true

  tags = {
    Environment = "Production"
  }
}
```

**Attaching the identity to a VM or AKS cluster:**

```hcl
resource "azurerm_linux_virtual_machine" "example" {
  # ... other config ...

  identity {
    type         = "UserAssigned"
    identity_ids = [module.security.identity_id]
  }
}
```

Once attached, application code running on that resource can use `DefaultAzureCredential` (or equivalent SDK pattern) to authenticate as this identity automatically, no stored credential required.

See [`examples/security`](../../examples/security/) for a complete, deployable example.