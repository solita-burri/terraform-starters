terraform {
  backend "local" {}
  required_providers {
    azurerm = "= 2.99.0"
  }
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}

data "azurerm_client_config" "current" {
}

data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

# First we create a storage account with a blob container
resource "azurerm_storage_account" "log-storage" {
  name                     = "${var.application_name}log${var.environment}st"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
}

resource "azurerm_storage_container" "log-container" {
  name                 = "debug-logs"
  storage_account_name = azurerm_storage_account.log-storage.name
}

# Then we generate an appropriate Shared Access Signature
data "azurerm_storage_account_blob_container_sas" "debug-log" {
  connection_string = azurerm_storage_account.log-storage.primary_connection_string
  container_name    = azurerm_storage_container.log-container.name
  start             = "2022-04-27"
  expiry            = "2040-01-01" # Verify so these match your needs / policies
  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = false
    list   = true
  }
}

# This is the the magic part of formatting the SAS url correctly for App Service
resource "azurerm_key_vault_secret" "debug-log-sas" {
  name         = "debug-log-sas"
  value        = join("", [azurerm_storage_account.log-storage.primary_blob_endpoint, azurerm_storage_container.log-container.name, data.azurerm_storage_account_blob_container_sas.debug-log.sas])
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.application_name}-${var.environment}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "api_app" {
  name                = "${var.application_name}-${var.environment}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  https_only          = true

  site_config {
    ftps_state = "FtpsOnly"
    always_on  = true
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "ENV-NAME" = "${var.environment}"
  }

  logs {

    detailed_error_messages_enabled = true

    application_logs {
      azure_blob_storage {
        level             = "Information"
        retention_in_days = 25
        sas_url           = azurerm_key_vault_secret.debug-log-sas.value # And here we use the magic
      }
    }
  }
}
