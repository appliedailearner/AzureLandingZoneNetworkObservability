resource "azurerm_resource_group" "onprem" {
  name     = "rg-onprem-sim-uks"
  location = var.location
}

resource "azurerm_virtual_network" "onprem" {
  name                = "vnet-onprem-uks"
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name
  address_space       = [var.onprem_vnet_cidr]
}

resource "azurerm_subnet" "server" {
  name                 = "ServerSubnet"
  resource_group_name  = azurerm_resource_group.onprem.name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = [var.onprem_subnet_cidr]
}
