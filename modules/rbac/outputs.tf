
output "readers_group_object_id" {
  value = azuread_group.readers.object_id
}

output "contributors_group_object_id" {
  value = azuread_group.contributors.object_id
}
