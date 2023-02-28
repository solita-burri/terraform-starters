terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.42.0"
    }
  }
  required_version = "~> 1.3.5"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  storage_use_azuread = true
  features {
  }
}

data "azurerm_client_config" "current" {
}

locals {
  common_tags = {
    Supplier    = "Placeholder"
    Application = "Placeholder"
  }
}

data "azurerm_resource_group" "main" {
  name = var.rg_name
}
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.org_id}-${var.hub_spoke_id}-${var.environment}-${var.service}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  internet_query_enabled = false
  tags                   = local.common_tags
}
