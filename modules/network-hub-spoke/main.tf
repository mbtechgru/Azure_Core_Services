
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "${var.resource_group_name}-hub-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.hub_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "hub_subnets" {
  for_each             = var.hub_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

resource "azurerm_virtual_network" "spokes" {
  for_each            = var.spoke_vnets
  name                = "${var.resource_group_name}-${each.key}-spoke-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [each.value.cidr]
  tags                = var.tags
}

locals {
  spoke_subnet_map = merge([
    for vnet_key, vnet in var.spoke_vnets : {
      for sn_key, sn_cidr in vnet.subnets :
      "${vnet_key}.${sn_key}" => {
        vnet_key = vnet_key
        name     = sn_key
        cidr     = sn_cidr
      }
    }
  ]...)
}

resource "azurerm_subnet" "spokes" {
  for_each             = local.spoke_subnet_map
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spokes[each.value.vnet_key].name
  address_prefixes     = [each.value.cidr]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                     = azurerm_virtual_network.spokes
  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = each.value.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                     = azurerm_virtual_network.spokes
  name                         = "peer-${each.key}-to-hub"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = each.value.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
