resource "azurerm_service_plan" "app" {
  name                = "asp-${var.webapp_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app" {
  name                = var.webapp_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app.id

  site_config {
    always_on = false # B1 doesn't support Always On? Standard does. B1 is basic.
    application_stack {
      python_version = "3.9"
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.app.id
  subnet_id      = var.subnet_id
}
