resource "random_password" "mssql" {
  length           = 25
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "azurerm_mssql_server" "main" {
  name                              = "sql-${var.org_id}-${var.environment}-${var.service}"
  resource_group_name               = data.azurerm_resource_group.main.name
  location                          = data.azurerm_resource_group.main.location
  version                           = "12.0"
  primary_user_assigned_identity_id = azurerm_user_assigned_identity.sql.id

  administrator_login          = "solutionserveradmin"
  administrator_login_password = random_password.mssql.result

  azuread_administrator {
    login_username = var.db_admin_username
    object_id      = var.admin_object_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.sql.id]
  }

  tags = local.common_tags
}


resource "azurerm_mssql_server_transparent_data_encryption" "main-sql-tde" {
  server_id        = azurerm_mssql_server.main.id
  key_vault_key_id = azurerm_key_vault_key.cmk-main.id
}
resource "azurerm_mssql_database" "main" {
  name                           = "sqldb-main-${var.environment}"
  server_id                      = azurerm_mssql_server.main.id
  collation                      = "Finnish_Swedish_CI_AS"
  maintenance_configuration_name = "SQL_WestEurope_DB_2"
  auto_pause_delay_in_minutes    = 60
  max_size_gb                    = 32
  min_capacity                   = 0.5
  read_replica_count             = 0
  read_scale                     = false
  sku_name                       = var.db_sku
  zone_redundant                 = true

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "mssql" {
  name                = "pe-${var.org_id}-${var.environment}-${var.service}-sql"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "privateserviceconnection"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  ip_configuration {
    name               = "privateipconfig"
    subresource_name   = "sqlServer"
    private_ip_address = var.network_config.sql_endpoint
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.mssql.id]
  }
}
# psql Privatelink private zone
resource "azurerm_private_dns_zone" "mssql" {
  name                = "database.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mssql" {
  name                  = "link-mssql"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mssql.name
  virtual_network_id    = data.azurerm_virtual_network.main.id

}