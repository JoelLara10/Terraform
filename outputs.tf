output "aplication_name" {
  value = random_string.suffix.result
}

output "unique_name" {
  value = local.unique_name
}