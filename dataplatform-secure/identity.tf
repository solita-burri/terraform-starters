
resource "azurerm_user_assigned_identity" "adf" {
  name                = "id-${var.org_id}-${var.service}-${var.environment}-adf"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_user_assigned_identity" "stg" {
  name                = "id-${var.org_id}-${var.service}-${var.environment}-stg"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_user_assigned_identity" "sql" {
  name                = "id-${var.org_id}-${var.service}-${var.environment}-sql"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}
