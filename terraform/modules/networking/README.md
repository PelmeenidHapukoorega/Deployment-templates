# Networking Module

Reusable Terraform module for deploying a `secure-by-default` Azure VNet with configurable subnets and NSG rules.

Built after repeatedly hand-rolling VNets, subnets, and NSGs across multiple lab projects: this standardises that pattern with sensible security defaults baked in.

## Security posture

Module is secure by default:

| Rule | Default behaviour |
|------|-------------------|
| HTTP (80) inbound | Denied unless `enable_http = true` |
| HTTPS (443) inbound | Denied unless `enable_https = true` |
| Management ports (SSH/RDP) | Denied unless `management_allowed_cidr` is set |
| All other inbound traffic | Denied |
| All outbound traffic | Allowed |

**Management access is intentionally restrictive.** `management_allowed_cidr` must be a single IP with a `/32` suffix — the module will reject a CIDR range. This forces deliberate, scoped access rather than accidentally opening SSH/RDP to a wide range or the entire internet.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `prefix` | string | — | Naming prefix applied to all resources |
| `location` | string | — | Azure region to deploy into |
| `resource_group_name` | string | — | Name of an existing resource group to deploy into |
| `vnet_address_space` | list(string) | `["10.0.0.0/16"]` | Address space for the VNet |
| `subnets` | list(object) | `[{name = "default", address_prefixes = ["10.0.1.0/24"]}]` | List of subnets to create |
| `enable_http` | bool | `false` | Allow inbound HTTP from any source |
| `enable_https` | bool | `false` | Allow inbound HTTPS from any source |
| `management_allowed_cidr` | string | `null` | Single IP (/32) allowed to access management ports. Leave null to disable management access |
| `management_ports` | list(number) | `[22, 3389]` | Ports opened if `management_allowed_cidr` is set |
| `tags` | map(string) | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | ID of the created Vnet |
| `vnet_name` | Name of the created VNet |
| `subnet_ids` | Map of subnet name to subnet ID |
| `nsg_id` | ID of the NSG |

## Usage

```hcl
resource "azurerm_resource_group" "this" {
  name     = "myproject-rg"
  location = "westeurope"
}

module "networking" {
  source = "../../modules/networking"

  prefix               = "myproject"
  location             = "westeurope"
  resource_group_name  = azurerm_resource_group.this.name

  subnets = [
    {
      name             = "web"
      address_prefixes = ["10.0.1.0/24"]
    },
    {
      name             = "data"
      address_prefixes = ["10.0.2.0/24"]
    }
  ]

  enable_http             = true
  enable_https             = true
  management_allowed_cidr = "YOUR.IP.HERE/32"

  tags = {
    Environment = "Production"
  }
}
```

See [`examples/networking`](../../examples/networking/) for a complete, deployable example.