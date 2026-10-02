output "aplication_name" {
  value = random_string.suffix.result
}

output "unique_name" {
  value = local.unique_name
}

output "enable_monitoring" {
  value = var.enable_monitoring
}

output "regions" {
  value = var.regions
}

output "enviroment_tags" {
  value = var.enviroment_tags
}

output "aplication_config" {
  value = var.aplication_config
}

output "allowed_networks" {
  value = var.allowed_networks
}