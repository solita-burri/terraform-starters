resource "azurerm_data_factory" "main" {
  name                             = "adf-${var.org_id}-${var.environment}-${var.service}"
  location                         = data.azurerm_resource_group.main.location
  resource_group_name              = data.azurerm_resource_group.main.name
  managed_virtual_network_enabled  = true
  customer_managed_key_id          = azurerm_key_vault_key.cmk-main.id
  customer_managed_key_identity_id = azurerm_user_assigned_identity.adf.id
  public_network_enabled           = false

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.adf.id]
  }

  tags = local.common_tags
}


resource "azurerm_private_endpoint" "datafactory" {
  name                = "pe-${var.org_id}-${var.environment}-${var.service}-datafactory"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = data.azurerm_subnet.endpoints.id
  private_service_connection {
    name                           = "privateserviceconnection"
    private_connection_resource_id = azurerm_data_factory.main.id
    is_manual_connection           = false
    subresource_names              = ["datafactory"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.datafactory.id]
  }
}

# Privatelink private zone
resource "azurerm_private_dns_zone" "datafactory" {
  name                = "privatelink.datafactory.azure.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "datafactory" {
  name                  = "link-datafactory"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.datafactory.name
  virtual_network_id    = data.azurerm_virtual_network.main.id

}

# To grant ADF managed identity access to your db, run:
# CREATE USER "ADF-NAME" FROM EXTERNAL PROVIDER;
# ALTER ROLE db_datareader ADD MEMBER [ADF-NAME]

resource "azurerm_monitor_diagnostic_setting" "adf" {
  name                           = "diag-${var.service}-adf"
  target_resource_id             = azurerm_data_factory.main.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  log_analytics_destination_type = "Dedicated"
  enabled_log {
    category_group = "allLogs"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}