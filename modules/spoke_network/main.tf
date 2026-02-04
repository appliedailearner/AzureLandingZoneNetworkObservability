resource "azurerm_virtual_network" "spoke" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnet_cidr]

  # For WebApp VNet Integration (Delegation)
  dynamic "delegation" {
    for_each = var.enable_webapp_delegation ? [1] : []
    content {
      name = "delegation"
      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

resource "azurerm_network_security_group" "spoke" {
  name                = "nsg-${var.vnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowHubInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/16" # Assuming Hub CIDR, or pass as variable
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "spoke" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.spoke.id
}

# -------------------------------------------------------------------------
# Routing Gap Remediation: UDR Enforcement
# -------------------------------------------------------------------------
resource "azurerm_route_table" "spoke" {
  count               = var.firewall_private_ip != null ? 1 : 0
  name                = "rt-${var.vnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "ForceTrafficToFirewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "spoke" {
  count          = var.firewall_private_ip != null ? 1 : 0
  subnet_id      = azurerm_subnet.workload.id
  route_table_id = azurerm_route_table.spoke[0].id
}
