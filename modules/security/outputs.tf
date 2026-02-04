output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "waf_public_ip" {
  description = "The public IP address of the Application Gateway"
  value       = azurerm_public_ip.agw.ip_address
}
