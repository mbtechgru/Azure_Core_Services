
resource "azurerm_management_group" "corp" {
  display_name = var.mgmt_group_names.corp
}

resource "azurerm_management_group" "prod" {
  display_name               = var.mgmt_group_names.production
  parent_management_group_id = azurerm_management_group.corp.id
}

resource "azurerm_management_group" "nonprod" {
  display_name               = var.mgmt_group_names.nonproduction
  parent_management_group_id = azurerm_management_group.corp.id
}

resource "azurerm_management_group" "shared" {
  display_name               = var.mgmt_group_names.sharedservices
  parent_management_group_id = azurerm_management_group.corp.id
}

resource "azurerm_management_group_subscription_association" "prod_assoc" {
  management_group_id = azurerm_management_group.prod.id
  subscription_id     = var.subscription_ids.production
}

resource "azurerm_management_group_subscription_association" "nonprod_assoc" {
  management_group_id = azurerm_management_group.nonprod.id
  subscription_id     = var.subscription_ids.nonproduction
}

resource "azurerm_management_group_subscription_association" "shared_assoc" {
  management_group_id = azurerm_management_group.shared.id
  subscription_id     = var.subscription_ids.sharedservices
}
