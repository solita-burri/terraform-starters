resource "azurerm_storage_account" "landing" {
  name                     = "st${var.org_id}${var.hub_spoke_id}${var.service}${var.environment}001"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  public_network_access_enabled = true
  shared_access_key_enabled     = false

  sftp_enabled   = true
  is_hns_enabled = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.stg.id]
  }

  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }

  tags = local.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "blob" {
  name                           = "diag-${var.service}-blob-landing"
  target_resource_id             = "${azurerm_storage_account.landing.id}/blobservices/default"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  log_analytics_destination_type = "Dedicated"
  enabled_log {
    category = "StorageRead"

    retention_policy {
      enabled = false
    }
  }
  enabled_log {
    category = "StorageWrite"

    retention_policy {
      enabled = false
    }
  }
  enabled_log {
    category = "StorageDelete"

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

# https://github.com/hashicorp/terraform-provider-azurerm/issues/20199
resource "azurerm_storage_account_customer_managed_key" "main" {
  storage_account_id        = azurerm_storage_account.landing.id
  user_assigned_identity_id = azurerm_user_assigned_identity.stg.id
  key_vault_id              = azurerm_key_vault.cmk.id
  key_name                  = azurerm_key_vault_key.cmk-main.name
}

# Networking

resource "azurerm_private_endpoint" "endpoint" {
  name                = "pe-${var.org_id}-${var.environment}-${var.service}-st-001"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = data.azurerm_subnet.landing.id
  private_service_connection {
    name                           = "privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.landing.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  ip_configuration {
    name               = "privateipconfig"
    subresource_name   = "blob"
    private_ip_address = var.network_config.landing_blob_endpoint
  }
}

resource "azurerm_storage_container" "inbound" {
  name                  = "inbound"
  storage_account_name  = azurerm_storage_account.landing.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "sourcing" {
  name                  = "sourcing"
  storage_account_name  = azurerm_storage_account.landing.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "archive" {
  name                  = "archive"
  storage_account_name  = azurerm_storage_account.landing.name
  container_access_type = "private"
}

resource "azurerm_storage_account_local_user" "integration" {
  name                 = "azsftpintegration"
  storage_account_id   = azurerm_storage_account.landing.id
  home_directory       = "/"
  ssh_key_enabled      = false
  ssh_password_enabled = true

  permission_scope {
    service       = "blob"
    resource_name = azurerm_storage_container.inbound.name
    permissions {
      read   = true
      create = true
      write  = true
      list   = true
    }
  }
}

resource "azurerm_key_vault_secret" "ensemble_sftp_password" {
  name         = "integration-sftp-password"
  value        = azurerm_storage_account_local_user.integration.password
  key_vault_id = azurerm_key_vault.main.id
}
