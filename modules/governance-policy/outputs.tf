
output "allowed_locations_policy_assignment_id" {
  value = azurerm_policy_assignment.allowed_locations.id
}

output "require_tags_policy_assignment_id" {
  value = azurerm_policy_assignment.require_tags.id
}
