
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "allowed-locations"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed locations"

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('listOfAllowedLocations')]"
      }
    }
    then = { effect = "Deny" }
  })

  parameters = jsonencode({
    listOfAllowedLocations = {
      type     = "Array"
      metadata = { displayName = "Allowed locations" }
    }
  })
}

resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "pa-allowed-locations"
  scope                = var.mgmt_group_id_corp
  policy_definition_id = azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_policy_definition" "require_tags" {
  name         = "require-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require resource tags"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        for t in var.required_tags : {
          field  = "tags[${t}]"
          exists = "false"
        }
      ]
    }
    then = { effect = "Deny" }
  })
}

resource "azurerm_policy_assignment" "require_tags" {
  name                 = "pa-require-tags"
  scope                = var.mgmt_group_id_corp
  policy_definition_id = azurerm_policy_definition.require_tags.id
}
