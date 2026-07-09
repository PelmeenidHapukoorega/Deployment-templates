# Azure Deployment Templates

A library of reusable, security-first Terraform and Bicep modules for Azure infrastructure. Built to solve a real recurring problem: hand-rolling VNets, identities, storage accounts, and monitoring from scratch for every project, and repeatedly hitting the same SKU availability, RBAC, and security configuration issues.

Each module exists in both Terraform and Bicep, letting me use whichever tool fits a given project while keeping the same tested, secure-by-default patterns underneath.

## Modules

| Module | Terraform | Bicep | Purpose |
|--------|-----------|-------|---------|
| Networking | [terraform/modules/networking](terraform/modules/networking/) | [bicep/modules/networking](bicep/modules/networking/) | VNet, subnets, NSG with secure-by-default rules |
| Security baseline | [terraform/modules/security](terraform/modules/security/) | [bicep/modules/security](bicep/modules/security/) | User-assigned managed identity, optional Key Vault |
| Storage | [terraform/modules/storage](terraform/modules/storage/) | [bicep/modules/storage](bicep/modules/storage/) | Storage account, containers, identity-based access only |
| Observability | [terraform/modules/observability](terraform/modules/observability/) | [bicep/modules/observability](bicep/modules/observability/) | Log Analytics workspace, action group, CPU/memory alerts |

## Design principles

**Secure by default, everywhere.** Every module defaults to the most restrictive, most secure configuration. NSGs deny all inbound traffic unless explicitly opted into. Storage accounts disable public access by default. No module ever outputs a key or connection string, access is granted exclusively through managed identities and RBAC.

**Identity over secrets.** Following the principle that good infrastructure starts with good security: prefer managed identities for all Azure-to-Azure authentication. Key Vault exists only as a fallback for secrets that genuinely can't be avoided.

**Each module owns one responsibility.** The security module doesn't create storage accounts. The storage module doesnt create identities. Composition happens at the calling layer, a projects own template wires modules together by passing one module's outputs into another's inputs.

**Modules over hand-rolled resources.** Every module was born from repeatedly rebuilding the same VNet, NSG, identity, or storage account across separate Lab projects, and repeatedly hitting the same SKU/region availability issues. This library exists so that problem gets solved once, not every time.

**Both tools, same patterns.** Every module is implemented in both Terraform and Bicep with equivalent security posture and design decisions — differences between the two implementations are deliberate and documented where the tools genuinely diverge (see each module's README for tool-specific notes).

## Repo structure

```
azure-deployment-templates/
├── terraform/
│   ├── modules/
│   │   ├── networking/
│   │   ├── security/
│   │   ├── storage/
│   │   └── observability/
│   └── examples/
│       ├── networking/
│       ├── security/
│       ├── storage/
│       └── observability/
└── bicep/
    ├── modules/
    │   ├── networking/
    │   ├── security/
    │   ├── storage/
    │   └── observability/
    └── examples/
        ├── networking/
        ├── security/
        ├── storage/
        └── observability/
```

Each module folder contains the module code and its own README. Each example folder contains a complete, deployable configuration demonstrating that module and in some cases, composing it with other modules (e.g. the storage example uses the security module to obtain an identity, the observability example deploys a test VM to monitor).

## How to use a module

1. Pick a module from the table above and read its README for inputs, outputs, and design notes.
2. Reference it from your own project's Terraform or Bicep configuration:

**Terraform:**
```hcl
module "networking" {
  source = "path/to/azure-deployment-templates/terraform/modules/networking"

  prefix               = "myproject"
  location             = "westeurope"
  resource_group_name  = azurerm_resource_group.this.name
}
```

**Bicep:**
```bicep
module networking 'path/to/azure-deployment-templates/bicep/modules/networking/main.bicep' = {
  name: 'networkingDeployment'
  scope: rg
  params: {
    prefix: prefix
    location: location
  }
}
```

3. Compose multiple modules by passing one module's outputs into another's inputs, see the storage and observability examples for real composition patterns.

## Known limitations

**Bicep diagnostic settings arent fully generic.** The observability module's Terraform version accepts arbitrary resource IDs for diagnostic settings; the Bicep version cannot, since biceps diagnostic settings require a symbolic resource reference rather than an arbitrary ID string. See the [observability module's Bicep README](bicep/modules/observability/README.md) for the caller-side workaround.

**No cross-region failover built in.** Each module deploys to a single region. Multi-region patterns (like Lab 04's database loop) would need to be composed at the calling layer.

**No automated testing pipeline yet.** Modules are manually deployed, verified, and destroyed during development. A future improvement would be a CI pipeline that runs `terraform validate`/`bicep build` and a test deployment on every push.

## What I learned building this

This project came out of a simple frustration — being tired of manually recreating VNets, resource groups, and identities for every lab, and repeatedly hitting SKU and region availability issues I'd already solved before. Building a proper module library forced a level of precision I hadn't needed for a single-purpose project.

A few things that stood out:

**Terraform and Bicep solve the same problems differently, not just syntactically.** Bicep mirrors Azures actual ARM API shape closely: role assignments need raw GUIDs, diagnostic settings need symbolic scope references, resource-group-level resources cant be declared directly in a subscription-scoped file. Terraforms `azurerm` provider adds a convenience layer on top of that same API: role names get resolved to GUIDs automatically `target_resource_id` accepts any string. Neither is "better" they are different levels of abstraction over the same underlying platform. Although i prefer Terraform over Bicep purely because of the simplicity.

**`count`/`for_each` conditionals require discipline.** Any time one resources existence depends on anothers (a role assignment depending on a Key Vault, an alert depending on an action group), both need the *same* condition, or you risk referencing something that doesnt exist. This bit me more than once, in both languages.

**Not every Azure metric behaves the way you'd assume.** CPU alerts use percentage. Memory alerts use raw bytes. Getting this wrong doesnt throw an error, it just silently creates an alert that will never fire.

**Biceps extension resources have real structural limits.** Diagnostic settings genuinely cant be as generic in Bicep as they are in Terraform, not a workaround-able inconvenience more like a real difference in how the two tools model scope.

**Committing granularly changed how much I actually retained.** Writing a real commit message for each small piece of work, including the mistakes forced me to articulate what I had just done before moving on, which stuck far better than writing one big commit per finished module.