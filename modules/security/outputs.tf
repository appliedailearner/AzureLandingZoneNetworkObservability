output "firewall_private_ip" {
  value = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  value = azurerm_public_ip.fw.ip_address
}

output "agw_public_ip" {
  value = azurerm_public_ip.agw.ip_address
}
