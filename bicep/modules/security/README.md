# Security Baseline Module (Bicep)

Reusable Bicep module for deploying a user-assigned managed identity as the primary building block for identity-based authentication, with an optional Key Vault for the residual secrets that can't use managed identity.

Direct Bicep equivalent of the Terraform security module in this repo: same design philosophy, same security posture, different syntax.

## Design philosophy

**The managed identity is the primary deliverable of this module, always created.** It can be attached to VMs, AKS clusters, App Services, or any Azure resource that supports user-assigned identities, enabling passwordless authentication to other Azure services.

**Key Vault is optional and secondary**, created only when `enableKeyVault = true`. Reserve it for secrets that genuinely cant be avoided: non-Azure API keys, certificates, connection strings for external systems. For anything Azure-to-Azure, prefer wiring up the managed identity directly.

**When Key Vault is created:**
- RBAC authorization mode (not legacy access policies)
- Soft delete enabled, 7-day retention
- Purge protection enabled
- The managed identity is automatically granted `Key Vault Secrets User` on it via role definition GUID `4633458b-17de-408a-b874-0445c86b69e6`

**Note on role assignment:** unlike the Terraform version, which resolves role names to GUIDs automatically via the provider, Bicep requires the raw role definition GUID directly: Bicep is a thinner layer over the ARM API, which never accepted human-readable role names.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `prefix` | string | — | Naming prefix applied to all resources |
| `location` | string | — | Azure region to deploy into |
| `enableKeyVault` | bool | `false` | Create a KV alongside the managed identity |
| `keyVaultSku` | string | `'standard'` | SKU for the KV, if created |
| `tags` | object | `{}` | Tags applied to all resources |

**Note:** unlike the Terraform version, this module does not take a `resourceGroupName` or `tenantId` parameter. Resource group scoping is handled by the caller via the `scope` property when invoking the module, and the tenant ID is resolved automatically using Bicep's `tenant()` function.

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `identityId` | string | Resource ID of the managed identity |
| `identityPrincipalId` | string | Principal ID of the identity: use when granting it RBAC roles on other resources |
| `identityClientId` | string | Client ID of the identity: use in application code to request tokens |
| `keyVaultId` | string | Resource ID of the Key Vault, or empty string if not created |
| `keyVaultUri` | string | URI of the Key Vault, or empty string if not created |

**Note:** unlike the Terraform version, empty outputs return `''` rather than `null`. Biceps type system does not support nullable strings the same way Terraform does, so empty string is the convention used here to signal absence.

## Usage

```bicep
targetScope = 'subscription'

param prefix string = 'myproject'
param location string = 'westeurope'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${prefix}-rg'
  location: location
}

module security '../../modules/security/main.bicep' = {
  name: 'securityDeployment'
  scope: rg
  params: {
    prefix: prefix
    location: location
    enableKeyVault: true
    tags: {
      Environment: 'Production'
    }
  }
}
```

**Attaching the identity to a VM or AKS cluster:**

```bicep
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  // ... other config ...
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${security.outputs.identityId}': {}
    }
  }
}
```

**Important:** this template must be deployed at subscription scope since it creates its own resource group:

```bash
az deployment sub create \
  --name myDeployment \
  --location westeurope \
  --template-file main.bicep
```

See [`examples/security`](../../examples/security/) for a complete, deployable example.