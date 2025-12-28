
resource "azuread_group" "readers" {
  display_name     = var.reader_group_name
  security_enabled = true
}

resource "azuread_group" "contributors" {
  display_name     = var.contributor_group_name
  security_enabled = true
}

resource "azurerm_role_assignment" "corp_readers" {
  scope                = var.scope_mgmt_group_id
  role_definition_name = "Reader"
  principal_id         = azuread_group.readers.object_id
}

resource "azurerm_role_assignment" "corp_contributors" {
  scope                = var.scope_mgmt_group_id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.contributors.object_id
}
