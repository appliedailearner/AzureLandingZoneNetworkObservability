resource "azurerm_public_ip" "fw" {
  name                = "pip-fw-uks" # REVERT: Avoid lock conflict since it is already working
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "agw" {
  name                = "pip-agw-uks-${var.unique_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# -------------------------------------------------------------------------
# Azure Firewall Premium
# -------------------------------------------------------------------------

resource "azurerm_firewall_policy" "main" {
  name                = "afwp-uks-premium"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"

  intrusion_detection {
    mode = "Alert"
  }
}

resource "azurerm_firewall" "main" {
  name                = "afw-uks-premium"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.main.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}

# -------------------------------------------------------------------------
# Application Gateway WAF v2
# -------------------------------------------------------------------------

resource "azurerm_application_gateway" "main" {
  name                = "agw-uks-waf-${var.unique_id}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.waf_subnet_id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "my-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  backend_address_pool {
    name         = "my-backend-pool"
    ip_addresses = var.backend_ips
    fqdns        = var.backend_fqdns
  }

  backend_http_settings {
    name                                = "my-http-settings"
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "my-listener"
    frontend_ip_configuration_name = "my-frontend-ip-configuration"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "my-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "my-listener"
    backend_address_pool_name  = "my-backend-pool"
    backend_http_settings_name = "my-http-settings"
    priority                   = 1
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101" # Modern TLS 1.2+ Standard
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}

# -------------------------------------------------------------------------
# Firewall Policy Rules
# -------------------------------------------------------------------------

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "fp-rcg-main"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100

  application_rule_collection {
    name     = "app-rules"
    priority = 200
    action   = "Allow"
    rule {
      name = "allow-google-dns-check"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = ["www.google.com"]
    }
    rule {
      name = "allow-msft-updates"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = ["*.microsoft.com", "*.windowsupdate.com"]
    }
  }

  network_rule_collection {
    name     = "net-rules"
    priority = 100
    action   = "Allow"
    rule {
      name                  = "allow-dns"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["8.8.8.8", "8.8.4.4"]
      destination_ports     = ["53"]
    }
    rule {
      name                  = "allow-icmp"
      protocols             = ["ICMP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }
}

# -------------------------------------------------------------------------
# Diagnostics (Observability Link)
# -------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "fw" {
  name                       = "diag-fw-to-law"
  target_resource_id         = azurerm_firewall.main.id
  log_analytics_workspace_id = var.law_id

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
