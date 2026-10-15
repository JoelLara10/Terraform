output "resource_group" { value = azurerm_resource_group.lab.name }
output "app_url" { value = "https://${azurerm_linux_web_app.app.default_hostname}" }
output "postgres_host" { value = azurerm_postgresql_flexible_server.db.fqdn }
output "storage_account" { value = azurerm_storage_account.blob.name }
output "vm_name" { value = azurerm_linux_virtual_machine.worker.name }
output "vm_private_ip" { value = azurerm_network_interface.worker.private_ip_address }
output "app_principal_id" { value = azurerm_linux_web_app.app.identity[0].principal_id }
output "worker_principal_id" { value = azurerm_linux_virtual_machine.worker.identity[0].principal_id }
output "bootstrap_sql" {
  description = "Ejecutar UNA VEZ con el administrador Entra conectado a la base ineo desde la VNet."
  value       = <<-SQL
    \set ON_ERROR_STOP on
    SELECT * FROM pg_catalog.pgaadauth_create_principal_with_oid('ineo_app', '${azurerm_linux_web_app.app.identity[0].principal_id}', 'service', false, false);
    SELECT * FROM pg_catalog.pgaadauth_create_principal_with_oid('ineo_worker', '${azurerm_linux_virtual_machine.worker.identity[0].principal_id}', 'service', false, false);
    CREATE SCHEMA IF NOT EXISTS ineo;
    CREATE TABLE IF NOT EXISTS ineo.jobs (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, payload jsonb NOT NULL DEFAULT '{}', status text NOT NULL DEFAULT 'pending');
    GRANT CONNECT ON DATABASE ineo TO ineo_app, ineo_worker;
    GRANT USAGE ON SCHEMA ineo TO ineo_app, ineo_worker;
    GRANT SELECT, INSERT ON ineo.jobs TO ineo_app;
    GRANT SELECT, UPDATE ON ineo.jobs TO ineo_worker;
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ineo TO ineo_app;
  SQL
}
