terraform {
  backend "local" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.1.0" # Always lock provider versions and check changelogs when upgrading
    }
  }

}

locals {
  kvname = "${var.project}-${var.environment}-kv" # This is required to avoid circular references:
  # "KV" -> "KV access policy" -> "App Service Identity" -> "App service" -> "App service config" -> "Keyvault reference" -> "KV"
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
    }
  }
}

resource "azurerm_key_vault" "kv" {
  name                        = local.kvname
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_key_vault_secret" "secret" {
  name  = "secret-sauce"
  value = "szechuan"
  # Note that this value will be stored in the state in plain text. Should 
  # be just an initial value
  key_vault_id = azurerm_key_vault.kv.id
  lifecycle {
    ignore_changes = [value]
    # Ignore manual changes to the value. Allows the secret to be update manually
    # to the actual value
  }
}

resource "azurerm_key_vault_access_policy" "read_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_linux_web_app.api_app.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

resource "azurerm_key_vault_access_policy" "admin_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = var.developer_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Restore", "Recover", "Backup"
  ]
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.project}-${var.environment}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "api_app" {
  name                = "${var.project}-${var.environment}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.app_service_plan.id
  https_only          = true

  site_config {
    ftps_state                  = "FtpsOnly"
    always_on                   = true
    scm_use_main_ip_restriction = true

    application_stack {
      dotnet_version = "5.0"
    }

    dynamic "ip_restriction" {
      for_each = var.cidr_blocks_whitelist
      content {
        name       = "Whitelist"
        ip_address = ip_restriction.value
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "THIS_IS_CONFIG"       = "www.google.fi"
    "THIS_IS_KV_REFERENCE" = "@Microsoft.KeyVault(SecretUri=https://${local.kvname}.vault.azure.net/secrets/secret-sauce)"
  }
}
