output "vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "firewall_subnet_id" {
  value = azurerm_subnet.firewall.id
}

output "waf_subnet_id" {
  value = azurerm_subnet.waf.id
}

output "waf_nsg_id" {
  value = azurerm_network_security_group.waf.id
}
