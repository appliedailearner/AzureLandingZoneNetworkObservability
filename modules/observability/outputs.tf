output "law_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "law_workspace_id" {
  value = azurerm_log_analytics_workspace.main.workspace_id
}

output "workspace_location" {
  value = azurerm_log_analytics_workspace.main.location
}

output "law_resource_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "network_watcher_id" {
  value = azurerm_network_watcher.main.id
}

output "network_watcher_name" {
  value = azurerm_network_watcher.main.name
}

output "storage_account_id" {
  value = azurerm_storage_account.flowlogs.id
}
