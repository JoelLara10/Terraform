output "resource_group_name" {
    value = azurerm_resource_group.rg.name
}

output "resource_group_id" {
    value = azurerm_resource_group.rg.id
}
output "virtual_network_name" {
    value = azurerm_virtual_network.vnet.name
}

output "virtual_network_id" {
    value = azurerm_virtual_network.vnet.id
}

output "virtual_network_address_space" {
    value = azurerm_virtual_network.vnet.address_space
}