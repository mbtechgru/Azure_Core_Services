# Azure Core Foundation (Terraform)

Bootstraps a production-ready Azure landing zone for MB Technology Group. Running this repo once provisions the full governance, networking, monitoring, backup, cost, and security baseline for a multi-subscription Azure environment.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Repository Structure](#repository-structure)
4. [Module Reference](#module-reference)
5. [Input Variables](#input-variables)
6. [Step-by-Step Deployment](#step-by-step-deployment)
7. [Network Layout](#network-layout)
8. [Post-Deployment Checklist](#post-deployment-checklist)
9. [Teardown](#teardown)
10. [Notes & Constraints](#notes--constraints)

---

## Architecture Overview

```
Tenant Root Group
└── Corp  (management group)
    ├── Production        → production subscription
    ├── Non-Production    → nonproduction subscription
    └── Shared-Services   → sharedservices subscription
                              ├── rg-shared-network   (Hub VNet + Spoke peerings)
                              ├── rg-shared-monitoring (Log Analytics Workspace)
                              └── rg-shared-backup    (Recovery Services Vault)
```

Governance policies (allowed locations, required tags) and RBAC groups (Readers / Contributors) are assigned at the **Corp** management group level so they inherit down to all child subscriptions automatically.

---

## Prerequisites

| Requirement | Version / Notes |
|---|---|
| Terraform | >= 1.6.0 |
| Azure CLI | Latest recommended (`az --version`) |
| AzureRM provider | >= 4.0.0 (pinned in `.terraform.lock.hcl`) |
| AzureAD provider | >= 3.0.0 |
| Azure account permissions | **Owner** or **User Access Administrator** at the **Tenant Root Group** level (required for management group and RBAC operations) |
| Subscriptions | Three existing subscriptions: `production`, `nonproduction`, `sharedservices` — created outside Terraform via the Azure Portal, EA enrollment, or MCA |

> **Tip:** Verify your management-group write permissions before applying:
> ```bash
> az account management-group list --output table
> ```

---

## Repository Structure

```
Azure_Core_Services/
├── main.tf                        # Root module — wires all child modules together
├── variables.tf                   # Root input variable declarations
├── providers.tf                   # AzureRM + AzureAD provider configuration
├── versions.tf                    # Terraform & provider version constraints
├── terraform.tfvars.example       # Template — copy to terraform.tfvars and fill in
└── modules/
    ├── management-groups/         # Corp hierarchy + subscription associations
    ├── governance-policy/         # Allowed-locations & required-tags policies
    ├── rbac/                      # Azure AD security groups + role assignments
    ├── network-hub-spoke/         # Hub VNet, spoke VNets, bidirectional peerings
    ├── monitoring/                # Log Analytics Workspace
    ├── backup/                    # Recovery Services Vault
    ├── cost-management/           # Monthly subscription budget + email alerts
    └── defender/                  # Defender for Cloud — VMs Standard tier
```

---

## Module Reference

### `management-groups`
Creates a four-level management group hierarchy and associates each existing subscription into its appropriate group.

| Resource | Name |
|---|---|
| Management Group | Corp |
| Management Group | Production (child of Corp) |
| Management Group | Non-Production (child of Corp) |
| Management Group | Shared-Services (child of Corp) |
| Subscription association | production → Production MG |
| Subscription association | nonproduction → Non-Production MG |
| Subscription association | sharedservices → Shared-Services MG |

---

### `governance-policy`
Attaches two custom Azure Policy definitions at the Corp management group scope so every child subscription inherits them.

| Policy | Effect | Details |
|---|---|---|
| `allowed-locations` | Deny | Blocks resource creation in any region outside `var.location` |
| `require-tags` | Deny | Rejects resources missing any of: `Owner`, `Environment`, `CostCenter` |

---

### `rbac`
Creates two Azure AD security groups and assigns built-in roles at the Corp management group scope.

| AD Group | Role | Scope |
|---|---|---|
| `{org_prefix}-cloud-readers` | Reader | Corp management group |
| `{org_prefix}-cloud-contributors` | Contributor | Corp management group |

Add users to these groups in Azure AD / Entra ID to grant subscription-wide access.

---

### `network-hub-spoke`
Deploys a hub VNet with dedicated subnets and one spoke VNet per environment. Bidirectional VNet peering (forwarded traffic enabled) is created between the hub and every spoke.

See [Network Layout](#network-layout) for full CIDR details.

---

### `monitoring`
Deploys a Log Analytics Workspace in the shared-services subscription.

| Setting | Value |
|---|---|
| SKU | PerGB2018 |
| Retention | 30 days |
| Resource group | `{org_prefix}-rg-shared-monitoring` |
| Workspace name | `{org_prefix}-law-core` |

---

### `backup`
Deploys a Recovery Services Vault for VM and file-share backup.

| Setting | Value |
|---|---|
| SKU | Standard |
| Resource group | `{org_prefix}-rg-shared-backup` |
| Vault name | `{org_prefix}-rsv-core` |

---

### `cost-management`
Creates a monthly consumption budget on the sharedservices subscription with two email notification thresholds.

| Threshold | Trigger |
|---|---|
| 80 % | Alert email when spend exceeds 80 % of `monthly_budget` |
| 100 % | Alert email when spend exceeds 100 % of `monthly_budget` |

Default budget: **$2,000 / month**. Alert emails are sent to `billing@example.com` — update this in `main.tf` before applying.

---

### `defender`
Enables Microsoft Defender for Cloud at the **Standard** (paid) tier for Virtual Machines on the sharedservices subscription.

---

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `location` | `string` | `"eastus"` | Primary Azure region for all resources |
| `org_prefix` | `string` | `"mbtg"` | Short prefix used in all resource names |
| `mgmt_group_names.corp` | `string` | `"Corp"` | Display name for the root corporate MG |
| `mgmt_group_names.production` | `string` | `"Production"` | Display name for the production MG |
| `mgmt_group_names.nonproduction` | `string` | `"Non-Production"` | Display name for the non-production MG |
| `mgmt_group_names.sharedservices` | `string` | `"Shared-Services"` | Display name for the shared-services MG |
| `subscription_ids.production` | `string` | *(required)* | Existing production subscription GUID |
| `subscription_ids.nonproduction` | `string` | *(required)* | Existing non-production subscription GUID |
| `subscription_ids.sharedservices` | `string` | *(required)* | Existing shared-services subscription GUID |
| `tags` | `map(string)` | See example | Baseline tags applied to all resources |

---

## Step-by-Step Deployment

### Step 1 — Clone and configure variables

```bash
# Navigate into the module directory
cd Azure_Core_Services

# Create your tfvars from the example template
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and replace the placeholder GUIDs with your real subscription IDs:

```hcl
location   = "eastus"
org_prefix = "mbtg"

subscription_ids = {
  production     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  nonproduction  = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
  sharedservices = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
}

tags = {
  Owner       = "MB Technology Group"
  ManagedBy   = "Terraform"
  Environment = "Shared"
  CostCenter  = "0000"
}
```

> Find your subscription IDs with: `az account list --output table`

---

### Step 2 — Update billing contact

Open `main.tf` and change the cost-management email to your actual billing address:

```hcl
module "cost_management" {
  ...
  emails = ["your-billing-team@yourdomain.com"]
}
```

---

### Step 3 — Authenticate to Azure

```bash
# Interactive login (recommended for first-time use)
az login

# Confirm you are targeting the correct tenant
az account show --output table

# If you have multiple tenants, specify the tenant explicitly
az login --tenant <tenant-id>
```

---

### Step 4 — Set the active subscription context

Terraform uses the AzureRM provider which reads the active subscription from the Azure CLI context. Point it to the sharedservices subscription (where most shared resources land):

```bash
az account set --subscription "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
```

---

### Step 5 — Initialize Terraform

Downloads all provider plugins and resolves module sources:

```bash
terraform init
```

Expected output includes confirmation that `hashicorp/azurerm` and `hashicorp/azuread` providers were installed.

---

### Step 6 — Review the plan

Generates an execution plan without making any changes. Review every resource before applying:

```bash
terraform plan -out tfplan
```

The plan should show approximately **30–40 resources** to be created across management groups, policies, RBAC, networking, monitoring, backup, cost management, and Defender.

---

### Step 7 — Apply

```bash
terraform apply tfplan
```

Terraform will create all resources in dependency order. Total runtime is typically **3–8 minutes**.

> **Note:** Management group policy assignments can take a few minutes to propagate before they are enforced on new resources.

---

### Step 8 — Verify deployment

After apply completes, run these checks:

```bash
# Confirm management groups exist
az account management-group list --output table

# Confirm resource groups were created
az group list --output table | grep mbtg

# Confirm VNets and peerings
az network vnet list --resource-group mbtg-rg-shared-network --output table
az network vnet peering list --resource-group mbtg-rg-shared-network --vnet-name mbtg-rg-shared-network-hub-vnet --output table

# Confirm Log Analytics Workspace
az monitor log-analytics workspace list --output table

# Confirm Recovery Services Vault
az backup vault list --output table
```

---

## Network Layout

### Hub VNet — `10.0.0.0/16`

| Subnet | CIDR | Purpose |
|---|---|---|
| `AzureFirewallSubnet` | `10.0.1.0/24` | Azure Firewall (reserved name required by Azure) |
| `AzureBastionSubnet` | `10.0.2.0/27` | Azure Bastion (reserved name required by Azure) |
| `SharedServices` | `10.0.10.0/24` | Shared infrastructure services |

### Spoke VNets

| Spoke | VNet CIDR | Subnet | CIDR |
|---|---|---|---|
| `prod` | `10.1.0.0/16` | `web` | `10.1.1.0/24` |
| | | `app` | `10.1.2.0/24` |
| | | `db` | `10.1.3.0/24` |
| `dev` | `10.2.0.0/16` | `web` | `10.2.1.0/24` |
| | | `app` | `10.2.2.0/24` |
| | | `db` | `10.2.3.0/24` |

All spoke VNets are peered to the hub with `allow_forwarded_traffic = true` in both directions.

---

## Post-Deployment Checklist

- [ ] Add users to `mbtg-cloud-readers` and `mbtg-cloud-contributors` groups in Entra ID
- [ ] Deploy Azure Firewall into `AzureFirewallSubnet` and configure UDRs on spoke subnets
- [ ] Deploy Azure Bastion into `AzureBastionSubnet` for secure VM access
- [ ] Configure Log Analytics diagnostic settings to route Azure Activity Log to `mbtg-law-core`
- [ ] Create backup policies in the Recovery Services Vault and protect workloads
- [ ] Verify Defender for Cloud recommendations in the Azure Portal (Security Center)
- [ ] Update `CostCenter` tag value in `terraform.tfvars` to match your finance tracking codes
- [ ] Enable Terraform remote state (Azure Storage Account or Terraform Cloud) before sharing with the team

---

## Teardown

To destroy all resources managed by this configuration:

```bash
terraform destroy
```

> **Warning:** This will remove the management group hierarchy, all policy assignments, RBAC groups, VNets, Log Analytics Workspace, Recovery Services Vault, and Defender pricing tier. Subscriptions themselves are **not** deleted (they were created outside Terraform).

---

## Notes & Constraints

- **Subscriptions must exist before applying.** Create them via the Azure Portal, an EA enrollment, or an MCA agreement. Reference their GUIDs in `subscription_ids`.
- **Management group operations require elevated permissions.** The deploying identity needs Owner or User Access Administrator at the Tenant Root Group. This cannot be granted through Terraform itself — it must be configured in the Azure Portal first.
- **Defender for Cloud Standard tier incurs cost.** The `defender` module enables the paid tier for Virtual Machines. Review [Defender pricing](https://azure.microsoft.com/en-us/pricing/details/defender-for-cloud/) before applying in production.
- **Policy propagation delay.** New policy assignments at a management group scope can take up to 30 minutes to fully propagate to all child resources.
- **Budget start date is hardcoded** to `2025-01-01` in `modules/cost-management/main.tf`. Update this value if deploying after that date to avoid Azure API validation errors.
