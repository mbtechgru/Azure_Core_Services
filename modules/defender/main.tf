
provider "azurerm" {
  alias           = "sub"
  features        {}
  subscription_id = var.subscription_id
}

resource "azurerm_security_center_subscription_pricing" "vm" {
  provider      = azurerm.sub
  tier          = "Standard"
  resource_type = "VirtualMachines"
}
