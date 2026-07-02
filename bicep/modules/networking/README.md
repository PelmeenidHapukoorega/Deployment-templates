# Networking Module (Bicep)

Reusable Bicep module for deploying a `secure-by-default` Azure Vnet with configurable subnets and NSG rules.

Direct Bicep equivalent of the Terraform networking module in this repo: same security posture, same design decisions, different syntax. Built to compare both tools side by side while solving the same real problem: hand-rolling VNets and NSGs for every project.

## Security posture

Identical security model to the Terraform version:

| Rule | Default behaviour |
|------|-------------------|
| HTTP (80) inbound | Denied unless `enableHttp = true` |
| HTTPS (443) inbound | Denied unless `enableHttps = true` |
| Management ports (SSH/RDP) | Denied unless `managementAllowedCidr` is set |
| All other inbound traffic | Denied |
| All outbound traffic | Allowed |

**Management access is intentionally restrictive.** `managementAllowedCidr` should be a single IP with a `/32` suffix, supplied by the caller: this module however does not enforce that format the way the Terraform version does with a validation block, since Bicep parameter validation for regex patterns is more limited. Treat this as the callers responsibility when using this module.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `prefix` | string | — | Naming prefix applied to all resources |
| `location` | string | — | Azure region to deploy into |
| `vnetAddressSpace` | array | `['10.0.0.0/16']` | Address space for the VNet |
| `subnets` | array | `[{name: 'default', addressPrefix: '10.0.1.0/24'}]` | List of subnets to create |
| `enableHttp` | bool | `false` | Allow inbound HTTP from any source |
| `enableHttps` | bool | `false` | Allow inbound HTTPS from any source |
| `managementAllowedCidr` | string | `''` | Single IP (/32) allowed to access management ports. Leave empty to disable management access |
| `managementPorts` | array | `[22, 3389]` | Ports opened if `managementAllowedCidr` is set |
| `tags` | object | `{}` | Tags applied to all resources |

**Note:** unlike the Terraform version, this module does not take a `resourceGroupName` parameter. Bicep resource group scoping is handled by the caller via the `scope` property when invoking the module — see Usage below.

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `vnetId` | string | ID of the created virtual network |
| `vnetName` | string | Name of the created virtual network |
| `subnetIds` | array | Subnet IDs, in the same order as the `subnets` input array |
| `nsgId` | string | ID of the network security group |

**Note:** unlike the Terraform version, `subnetIds` is an array rather than a map. Biceps loop comprehension syntax produces arrays natively; producing a keyed object requires the `toObject()` function, which was intentionally left out here for simplicity. Index into the array using the same order as your `subnets` input.

## Usage

```bicep
targetScope = 'subscription'

param prefix string = 'myproject'
param location string = 'westeurope'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${prefix}-rg'
  location: location
}

module networking '../../modules/networking/main.bicep' = {
  name: 'networkingDeployment'
  scope: rg
  params: {
    prefix: prefix
    location: location
    subnets: [
      { name: 'web', addressPrefix: '10.0.1.0/24' }
      { name: 'data', addressPrefix: '10.0.2.0/24' }
    ]
    enableHttp: true
    enableHttps: true
    managementAllowedCidr: 'YOUR.IP.HERE/32'
    tags: {
      Environment: 'Production'
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

See [`examples/networking`](../../examples/networking/) for a complete, deployable example.