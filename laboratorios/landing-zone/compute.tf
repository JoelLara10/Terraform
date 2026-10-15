resource "azurerm_network_interface" "worker" {
  name                = "nic-worker-${local.suffix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  ip_configuration {
    name                          = "private"
    subnet_id                     = azurerm_subnet.lab["vm"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.3.4"
  }
  tags = local.tags
}
resource "azurerm_linux_virtual_machine" "worker" {
  name                            = "vm-worker-${local.suffix}"
  location                        = azurerm_resource_group.lab.location
  resource_group_name             = azurerm_resource_group.lab.name
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  network_interface_ids           = [azurerm_network_interface.worker.id]
  disable_password_authentication = true
  identity { type = "SystemAssigned" }
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  custom_data = var.enable_vm_outbound ? base64encode(file("${path.module}/scripts/cloud-init.yaml")) : null
  tags        = local.tags
  depends_on  = [azurerm_subnet_network_security_group_association.lab, azurerm_subnet_nat_gateway_association.vm]
}
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${local.suffix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}
resource "azurerm_bastion_host" "lab" {
  name                = "bas-${local.suffix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "Basic"
  ip_configuration {
    name                 = "bastion"
    subnet_id            = azurerm_subnet.lab["bastion"].id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
  tags       = local.tags
  depends_on = [azurerm_subnet_network_security_group_association.lab]
}
