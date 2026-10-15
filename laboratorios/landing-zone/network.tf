# Subredes independientes; no mezclar bloques subnet inline dentro de la VNet.
resource "azurerm_virtual_network" "lab" {
  name                = "vnet-lz-prod"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}
resource "azurerm_subnet" "lab" {
  for_each                          = local.subnets
  name                              = each.value.name
  address_prefixes                  = [each.value.cidr]
  resource_group_name               = azurerm_resource_group.lab.name
  virtual_network_name              = azurerm_virtual_network.lab.name
  private_endpoint_network_policies = contains(["db", "endpoints"], each.key) ? "Enabled" : "Disabled"
  dynamic "delegation" {
    for_each = each.key == "app" ? [1] : []
    content {
      name = "app-service"
      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}
resource "azurerm_private_dns_zone" "lab" {
  for_each            = local.dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "lab" {
  for_each              = local.dns_zones
  name                  = "link-${each.key}"
  resource_group_name   = azurerm_resource_group.lab.name
  private_dns_zone_name = azurerm_private_dns_zone.lab[each.key].name
  virtual_network_id    = azurerm_virtual_network.lab.id
  registration_enabled  = false
  tags                  = local.tags
}
# Salida explicita de la VM; no expone SSH ni agrega IP publica a su NIC.
resource "azurerm_public_ip" "nat" {
  count               = var.enable_vm_outbound ? 1 : 0
  name                = "pip-nat-${local.suffix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}
resource "azurerm_nat_gateway" "vm" {
  count               = var.enable_vm_outbound ? 1 : 0
  name                = "nat-${local.suffix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku_name            = "Standard"
  tags                = local.tags
}
resource "azurerm_nat_gateway_public_ip_association" "vm" {
  count                = var.enable_vm_outbound ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.vm[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}
resource "azurerm_subnet_nat_gateway_association" "vm" {
  count          = var.enable_vm_outbound ? 1 : 0
  subnet_id      = azurerm_subnet.lab["vm"].id
  nat_gateway_id = azurerm_nat_gateway.vm[0].id
  depends_on     = [azurerm_nat_gateway_public_ip_association.vm]
}
