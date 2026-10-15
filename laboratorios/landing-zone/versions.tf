terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "= 4.81.0" }
    random  = { source = "hashicorp/random", version = "= 3.7.2" }
  }
}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  # Solo los proveedores usados; el usuario puede registrarlos antes con Azure CLI.
  resource_provider_registrations = "none"
}
data "azurerm_client_config" "current" {}
