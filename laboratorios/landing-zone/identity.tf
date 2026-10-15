# RBAC de datos de Blob al nivel del contenedor; no Owner/Contributor de suscripcion.
resource "azurerm_role_assignment" "app_blob" {
  scope                = "${azurerm_storage_account.blob.id}/blobServices/default/containers/${azurerm_storage_container.jobs.name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
resource "azurerm_role_assignment" "worker_blob" {
  scope                = "${azurerm_storage_account.blob.id}/blobServices/default/containers/${azurerm_storage_container.jobs.name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.worker.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
# PostgreSQL usa roles SQL de Entra. Azure RBAC no concede acceso SQL.
# Generar y ejecutar bootstrap_sql como administrador Entra dentro de la VNet.
