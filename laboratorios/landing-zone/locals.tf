resource "random_string" "unique" {
  length  = 6
  upper   = false
  special = false
}
locals {
  suffix = "${var.project}-${var.environment}-${random_string.unique.result}"
  tags = {
    project = var.project, environment = var.environment,
    owner   = var.owner, managed_by = "terraform", cost_center = "utvt"
  }
  subnets = {
    app       = { name = "snet-app", cidr = "10.0.1.0/24" }
    db        = { name = "snet-db", cidr = "10.0.2.0/24" }
    vm        = { name = "snet-vm", cidr = "10.0.3.0/24" }
    endpoints = { name = "snet-endpoints", cidr = "10.0.4.0/24" }
    bastion   = { name = "AzureBastionSubnet", cidr = "10.0.5.0/26" }
  }
  dns_zones = {
    postgres = "privatelink.postgres.database.azure.com"
    blob     = "privatelink.blob.core.windows.net"
  }
}
resource "azurerm_resource_group" "lab" {
  name     = "rg-${local.suffix}"
  location = var.location
  tags     = local.tags
}
