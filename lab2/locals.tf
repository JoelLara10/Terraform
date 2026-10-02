locals {
  resource_group_name  = "rg-${var.project_name}-${var.enviroment}-${var.location}-001"
  virtual_network_name = "vnet-${var.project_name}-${var.enviroment}-${var.location}-001"
  common_tags = merge(
    var.tags,
    {
      "Project"     = var.project_name
      "Environment" = var.enviroment
      "Location"    = var.location
    }
  )
}
