resource "azurerm_key_vault" "cmk" {
  name                        = "kv-${var.org_id}-${var.environment}-${var.service}-cmk"
  location                    = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"
  tags     = local.common_tags
}

resource "azurerm_key_vault_access_policy" "admins" {
  key_vault_id = azurerm_key_vault.cmk.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.admin_object_id
  key_permissions = [
    "Create", "Get", "List"
  ]
}

resource "azurerm_key_vault_access_policy" "adf" {
  key_vault_id = azurerm_key_vault.cmk.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.adf.principal_id

  key_permissions = [
    "Get", "WrapKey", "UnwrapKey"
  ]
}
resource "azurerm_key_vault_access_policy" "stg" {
  key_vault_id = azurerm_key_vault.cmk.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.stg.principal_id

  key_permissions = [
    "Get", "WrapKey", "UnwrapKey"
  ]
}
resource "azurerm_key_vault_access_policy" "sql" {
  key_vault_id = azurerm_key_vault.cmk.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.sql.principal_id
  key_permissions = [
    "Get", "WrapKey", "UnwrapKey"
  ]
}

resource "azurerm_key_vault_key" "cmk-main" {
  name         = "cmk-${var.service}-main"
  key_vault_id = azurerm_key_vault.cmk.id
  key_type     = var.cmk_type
  key_size     = var.cmk_size
  key_opts     = var.cmk_opts
}

resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.org_id}-${var.environment}-${var.service}-general"
  location                    = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"
  tags     = local.common_tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.admin_object_id

    key_permissions         = ["Create", "Get", "List"]
    secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
    certificate_permissions = ["Get", "List"]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions         = ["Create", "Get", "List"]
    secret_permissions      = ["Get", "List", "Set", "Recover", "Backup", "Restore"]
    certificate_permissions = ["Get", "List"]
  }
}

