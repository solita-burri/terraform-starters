# Create a virtual network within the resource group
data "azurerm_virtual_network" "main" {
  name                = var.network_config.vnet_name
  resource_group_name = var.network_config.rg_name
}

data "azurerm_subnet" "endpoints" {
  name                 = var.network_config.endpoint_subnet
  resource_group_name  = var.network_config.rg_name
  virtual_network_name = var.network_config.vnet_name
}

data "azurerm_subnet" "shir" {
  name                 = var.network_config.shir_subnet
  resource_group_name  = var.network_config.rg_name
  virtual_network_name = var.network_config.vnet_name
}

data "azurerm_subnet" "landing" {
  name                 = var.network_config.landing_subnet
  resource_group_name  = var.network_config.rg_name
  virtual_network_name = var.network_config.vnet_name
}

/*

## Create a NAT gateway for a static outbound IP from the SHIR

resource "azurerm_public_ip" "nat" {
  name                = "pip-${var.org_id}-${var.hub_spoke_id}-${var.environment}-${var.service}-shir"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "main" {
  name                = "nat-${var.org_id}-${var.hub_spoke_id}-${var.service}-shir-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_subnet_nat_gateway_association" "shir" {
  subnet_id      = data.azurerm_subnet.shir.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_nat_gateway_public_ip_association" "shir" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}
*/