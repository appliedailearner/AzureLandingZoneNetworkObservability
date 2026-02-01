output "vnet_id" {
  value = azurerm_virtual_network.onprem.id
}
output "vnet_name" {
  value = azurerm_virtual_network.onprem.name
}
output "resource_group_name" {
  value = azurerm_resource_group.onprem.name
}
