
module "management_groups" {
  source = "./modules/management-groups"

  mgmt_group_names = var.mgmt_group_names
  subscription_ids = var.subscription_ids
}

module "governance_policy" {
  source = "./modules/governance-policy"

  mgmt_group_id_corp = module.management_groups.corp_mg_id
  allowed_locations  = [var.location]
  required_tags      = ["Owner", "Environment", "CostCenter"]
}

module "rbac" {
  source = "./modules/rbac"

  scope_mgmt_group_id    = module.management_groups.corp_mg_id
  reader_group_name      = "${var.org_prefix}-cloud-readers"
  contributor_group_name = "${var.org_prefix}-cloud-contributors"
}

module "network" {
  source = "./modules/network-hub-spoke"

  location            = var.location
  resource_group_name = "${var.org_prefix}-rg-shared-network"
  tags                = var.tags

  hub_vnet_cidr = "10.0.0.0/16"
  hub_subnets = {
    AzureFirewallSubnet = "10.0.1.0/24"
    AzureBastionSubnet  = "10.0.2.0/27"
    SharedServices      = "10.0.10.0/24"
  }

  spoke_vnets = {
    prod = {
      cidr = "10.1.0.0/16"
      subnets = {
        web = "10.1.1.0/24"
        app = "10.1.2.0/24"
        db  = "10.1.3.0/24"
      }
    }
    dev = {
      cidr = "10.2.0.0/16"
      subnets = {
        web = "10.2.1.0/24"
        app = "10.2.2.0/24"
        db  = "10.2.3.0/24"
      }
    }
  }
}

module "monitoring" {
  source = "./modules/monitoring"

  location            = var.location
  resource_group_name = "${var.org_prefix}-rg-shared-monitoring"
  tags                = var.tags
  law_name            = "${var.org_prefix}-law-core"
}

module "backup" {
  source = "./modules/backup"

  location            = var.location
  resource_group_name = "${var.org_prefix}-rg-shared-backup"
  tags                = var.tags
  rsv_name            = "${var.org_prefix}-rsv-core"
}

module "cost_management" {
  source = "./modules/cost-management"

  subscription_id = var.subscription_ids.sharedservices
  monthly_budget  = 2000
  emails          = ["billing@example.com"]
}

module "defender" {
  source = "./modules/defender"

  subscription_id = var.subscription_ids.sharedservices
}
