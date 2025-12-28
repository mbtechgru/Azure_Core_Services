
# Azure Core Foundation (Terraform)

This repo bootstraps core Azure services:
- Management Groups + subscription associations
- Baseline RBAC groups (Readers/Contributors)
- Hub-and-spoke VNets + peerings
- Governance policies (allowed locations + required tags)
- Log Analytics workspace
- Recovery Services Vault
- Cost Management budget
- Defender for Cloud baseline (VMs)

## Usage

1. `cp terraform.tfvars.example terraform.tfvars` and edit values.
2. Authenticate:
   - `az login`
3. Deploy:
   - `terraform init`
   - `terraform plan -out tfplan`
   - `terraform apply tfplan`

## Notes
- Azure subscriptions should be created outside Terraform (Portal/EA/MCA), then referenced in `subscription_ids`.
