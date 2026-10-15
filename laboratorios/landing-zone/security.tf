locals {
  # direction, priority, protocol, source, destination, destination ports
  security_rules = {
    app = {
      pg           = ["Outbound", 100, "Tcp", "10.0.1.0/24", "10.0.2.4", "5432"]
      blob         = ["Outbound", 110, "Tcp", "10.0.1.0/24", "10.0.4.4", "443"]
      dns          = ["Outbound", 120, "*", "*", "AzurePlatformDNS", "53"]
      deny_lateral = ["Outbound", 4000, "*", "*", "VirtualNetwork", "*"]
      deny_in      = ["Inbound", 4096, "*", "*", "*", "*"]
    }
    db = {
      app     = ["Inbound", 100, "Tcp", "10.0.1.0/24", "10.0.2.4", "5432"]
      vm      = ["Inbound", 110, "Tcp", "10.0.3.0/24", "10.0.2.4", "5432"]
      deny_in = ["Inbound", 4096, "*", "*", "*", "*"]
    }
    endpoints = {
      app     = ["Inbound", 100, "Tcp", "10.0.1.0/24", "10.0.4.4", "443"]
      vm      = ["Inbound", 110, "Tcp", "10.0.3.0/24", "10.0.4.4", "443"]
      deny_in = ["Inbound", 4096, "*", "*", "*", "*"]
    }
    vm = {
      ssh  = ["Inbound", 100, "Tcp", "10.0.5.0/26", "10.0.3.0/24", "22"]
      pg   = ["Outbound", 100, "Tcp", "10.0.3.0/24", "10.0.2.4", "5432"]
      blob = ["Outbound", 110, "Tcp", "10.0.3.0/24", "10.0.4.4", "443"]
      dns  = ["Outbound", 120, "*", "*", "AzurePlatformDNS", "53"]
      # APT y HTTPS de identidad/repositorios; NAT es salida, no acceso de entrada.
      web          = ["Outbound", 130, "Tcp", "10.0.3.0/24", "Internet", "80,443"]
      deny_lateral = ["Outbound", 4000, "*", "*", "VirtualNetwork", "*"]
      deny_in      = ["Inbound", 4096, "*", "*", "*", "*"]
    }
    bastion = {
      https       = ["Inbound", 100, "Tcp", "Internet", "*", "443"]
      gateway     = ["Inbound", 110, "Tcp", "GatewayManager", "*", "443"]
      lb          = ["Inbound", 120, "Tcp", "AzureLoadBalancer", "*", "443"]
      control_in  = ["Inbound", 130, "*", "VirtualNetwork", "VirtualNetwork", "8080,5701"]
      ssh_rdp     = ["Outbound", 100, "*", "*", "VirtualNetwork", "22,3389"]
      azure       = ["Outbound", 110, "Tcp", "*", "AzureCloud", "443"]
      control_out = ["Outbound", 120, "*", "VirtualNetwork", "VirtualNetwork", "8080,5701"]
      sessions    = ["Outbound", 130, "*", "*", "Internet", "80"]
      deny_in     = ["Inbound", 4096, "*", "*", "*", "*"]
      deny_out    = ["Outbound", 4096, "*", "*", "*", "*"]
    }
  }
}
resource "azurerm_network_security_group" "lab" {
  for_each            = local.security_rules
  name                = "nsg-${each.key}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
  dynamic "security_rule" {
    for_each = each.value
    content {
      name                       = security_rule.key
      direction                  = security_rule.value[0]
      priority                   = tonumber(security_rule.value[1])
      protocol                   = security_rule.value[2]
      source_address_prefix      = security_rule.value[3]
      destination_address_prefix = security_rule.value[4]
      destination_port_range     = strcontains(security_rule.value[5], ",") ? null : security_rule.value[5]
      destination_port_ranges    = strcontains(security_rule.value[5], ",") ? split(",", security_rule.value[5]) : null
      source_port_range          = "*"
      access                     = startswith(security_rule.key, "deny") ? "Deny" : "Allow"
    }
  }
}
resource "azurerm_subnet_network_security_group_association" "lab" {
  for_each                  = local.subnets
  subnet_id                 = azurerm_subnet.lab[each.key].id
  network_security_group_id = azurerm_network_security_group.lab[each.key].id
}
