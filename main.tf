locals {
  resource_group_name = "rg-net-observability-uks"
}

resource "azurerm_resource_group" "hub" {
  name     = local.resource_group_name
  location = var.location_primary
}

# -------------------------------------------------------------------------
# 1. CORE NETWORKING (Hub)
# -------------------------------------------------------------------------
module "networking" {
  source                  = "./modules/networking"
  resource_group_name     = azurerm_resource_group.hub.name
  location                = azurerm_resource_group.hub.location
  vnet_cidr               = var.hub_vnet_cidr
  firewall_subnet_cidr    = var.firewall_subnet_cidr
  gateway_subnet_cidr     = var.gateway_subnet_cidr
  app_gateway_subnet_cidr = var.app_gateway_subnet_cidr
}

# -------------------------------------------------------------------------
# 2. SPOKE 1: VM Workload
# -------------------------------------------------------------------------
module "spoke1" {
  source              = "./modules/spoke_network"
  vnet_name           = "vnet-spoke1-uks"
  location            = var.location_primary
  resource_group_name = azurerm_resource_group.hub.name
  vnet_cidr           = "10.1.0.0/16"
  subnet_cidr         = "10.1.1.0/24"
  firewall_private_ip = module.security.firewall_private_ip
}

module "workload_vm_spoke1" {
  source              = "./modules/workload_vm"
  vm_name             = "vm-spoke1"
  location            = var.location_primary
  resource_group_name = azurerm_resource_group.hub.name
  subnet_id           = module.spoke1.subnet_id
}

# -------------------------------------------------------------------------
# 3. SPOKE 2: WebApp Workload
# -------------------------------------------------------------------------
module "spoke2" {
  source                   = "./modules/spoke_network"
  vnet_name                = "vnet-spoke2-uks"
  location                 = var.location_primary
  resource_group_name      = azurerm_resource_group.hub.name
  vnet_cidr                = "10.2.0.0/16"
  subnet_cidr              = "10.2.1.0/24"
  enable_webapp_delegation = true
  firewall_private_ip      = module.security.firewall_private_ip
}

module "workload_webapp_spoke2" {
  source              = "./modules/workload_webapp"
  webapp_name         = "app-spoke2-obs-${random_id.sa.hex}" # Unique Name
  location            = var.location_primary
  resource_group_name = azurerm_resource_group.hub.name
  subnet_id           = module.spoke2.subnet_id
}

# -------------------------------------------------------------------------
# 4. SECURITY (Firewall & WAF)
# -------------------------------------------------------------------------
module "security" {
  source              = "./modules/security"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  firewall_subnet_id  = module.networking.firewall_subnet_id
  waf_subnet_id       = module.networking.waf_subnet_id
  law_id              = module.observability.law_id
  unique_id           = random_id.sa.hex
}

# -------------------------------------------------------------------------
# 5. OBSERVABILITY (The Eyes)
# -------------------------------------------------------------------------
module "observability" {
  source              = "./modules/observability"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  target_nsg_id       = module.networking.waf_nsg_id
  source_vm_id        = module.workload_vm_spoke1.vm_id
  unique_id           = random_id.sa.hex
}

# Flow Logs for Spoke 1
resource "azurerm_network_watcher_flow_log" "spoke1" {
  network_watcher_name = module.observability.network_watcher_name
  resource_group_name  = azurerm_resource_group.hub.name
  location             = var.location_primary
  name                 = "flowlog-spoke1"
  target_resource_id   = module.spoke1.nsg_id
  storage_account_id   = module.observability.storage_account_id
  enabled              = true
  retention_policy {
    enabled = true
    days    = 7
  }
  traffic_analytics {
    enabled               = true
    workspace_id          = module.observability.law_workspace_id
    workspace_region      = var.location_primary
    workspace_resource_id = module.observability.law_resource_id
    interval_in_minutes   = 10
  }
}

# Flow Logs for Spoke 2
resource "azurerm_network_watcher_flow_log" "spoke2" {
  network_watcher_name = module.observability.network_watcher_name
  resource_group_name  = azurerm_resource_group.hub.name
  location             = var.location_primary
  name                 = "flowlog-spoke2"
  target_resource_id   = module.spoke2.nsg_id
  storage_account_id   = module.observability.storage_account_id
  enabled              = true
  retention_policy {
    enabled = true
    days    = 7
  }
  traffic_analytics {
    enabled               = true
    workspace_id          = module.observability.law_workspace_id
    workspace_region      = var.location_primary
    workspace_resource_id = module.observability.law_resource_id
    interval_in_minutes   = 10
  }
}

# -------------------------------------------------------------------------
# 6. HYBRID SIMULATION (On-Prem VNet)
# -------------------------------------------------------------------------
module "onprem_simulation" {
  source   = "./modules/onprem_sim"
  location = var.location_primary
}

resource "random_id" "sa" { byte_length = 4 }

# -------------------------------------------------------------------------
# 7. PEERING MESH (Hub <-> Spoke1, Hub <-> Spoke2, Hub <-> OnPrem)
# -------------------------------------------------------------------------
# Note: For brevity in this demo code, we are doing simple peering. 
# Production would use the Azure Firewall as the next hop (UDRs).

# Hub <-> OnPrem
resource "azurerm_virtual_network_peering" "hub_to_onprem" {
  name                      = "peer-hub-to-onprem"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.networking.vnet_name
  remote_virtual_network_id = module.onprem_simulation.vnet_id
}
resource "azurerm_virtual_network_peering" "onprem_to_hub" {
  name                      = "peer-onprem-to-hub"
  resource_group_name       = module.onprem_simulation.resource_group_name
  virtual_network_name      = module.onprem_simulation.vnet_name
  remote_virtual_network_id = module.networking.vnet_id
}

# Hub <-> Spoke 1
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                      = "peer-hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.networking.vnet_name
  remote_virtual_network_id = module.spoke1.vnet_id
}
resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                      = "peer-spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.spoke1.vnet_name
  remote_virtual_network_id = module.networking.vnet_id
}

# Hub <-> Spoke 2
resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                      = "peer-hub-to-spoke2"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.networking.vnet_name
  remote_virtual_network_id = module.spoke2.vnet_id
}
resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                      = "peer-spoke2-to-hub"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.spoke2.vnet_name
  remote_virtual_network_id = module.networking.vnet_id
}
