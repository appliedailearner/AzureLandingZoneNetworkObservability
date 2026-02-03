resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-net-obs-uks-${var.unique_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_network_watcher" "main" {
  name                = "nw-uks"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_storage_account" "flowlogs" {
  name                     = "stflowlogs${var.unique_id}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

/*
# -------------------------------------------------------------------------
# NSG Flow Logs (The Camera)
# -------------------------------------------------------------------------
resource "azurerm_network_watcher_flow_log" "waf" {
  network_watcher_name = azurerm_network_watcher.main.name
  resource_group_name  = var.resource_group_name
  name                 = "flowlog-agw-uks"

  network_security_group_id = var.target_nsg_id
  storage_account_id        = azurerm_storage_account.flowlogs.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.main.location
    workspace_resource_id = azurerm_log_analytics_workspace.main.id
    interval_in_minutes   = 10
  }
}
*/

# -------------------------------------------------------------------------
# Connection Monitor
# -------------------------------------------------------------------------
resource "azurerm_network_connection_monitor" "cm" {
  name               = "cm-connectivity-test"
  network_watcher_id = azurerm_network_watcher.main.id
  location           = var.location

  endpoint {
    name               = "source-vm"
    target_resource_id = var.source_vm_id
  }

  endpoint {
    name    = "destination-google"
    address = "8.8.8.8"
  }

  test_configuration {
    name                      = "tcp-ping"
    protocol                  = "Tcp"
    test_frequency_in_seconds = 60
    tcp_configuration {
      port = 53
    }
  }

  test_group {
    name                     = "group-vm-to-internet"
    destination_endpoints    = ["destination-google"]
    source_endpoints         = ["source-vm"]
    test_configuration_names = ["tcp-ping"]
  }
}

