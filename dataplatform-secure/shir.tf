locals {
  shir_vm_name = "vm${var.environment}shir01"
}

resource "random_password" "shir" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "azurerm_data_factory_integration_runtime_self_hosted" "main" {
  name            = "shir-${var.org_id}-${var.hub_spoke_id}-${var.environment}-${var.service}"
  data_factory_id = azurerm_data_factory.main.id
}


resource "azurerm_network_interface" "shir" {
  name                = "nic-${local.shir_vm_name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "private"
    subnet_id                     = data.azurerm_subnet.shir.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

resource "azurerm_windows_virtual_machine" "shir" {
  name                  = local.shir_vm_name
  location              = data.azurerm_resource_group.main.location
  resource_group_name   = data.azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.shir.id]
  size                  = var.shir_sku

  admin_username = var.shir_username
  admin_password = random_password.shir.result

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      admin_password
    ]
  }
}
