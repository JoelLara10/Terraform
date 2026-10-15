resource "azurerm_service_plan" "app" {
  name                = "asp-${local.suffix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.tags
}
resource "azurerm_linux_web_app" "app" {
  name                                           = "app-${local.suffix}"
  location                                       = azurerm_resource_group.lab.location
  resource_group_name                            = azurerm_resource_group.lab.name
  service_plan_id                                = azurerm_service_plan.app.id
  virtual_network_subnet_id                      = azurerm_subnet.lab["app"].id
  https_only                                     = true
  public_network_access_enabled                  = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  identity { type = "SystemAssigned" }
  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
    # El trafico privado va por VNet; salida publica de plataforma por App Service.
    vnet_route_all_enabled = false
    application_stack { node_version = "24-lts" }
  }
  app_settings = {
    PGHOST         = azurerm_postgresql_flexible_server.db.fqdn
    PGDATABASE     = azurerm_postgresql_flexible_server_database.app.name
    PGUSER         = "ineo_app"
    PGPORT         = "5432"
    PGSSLMODE      = "verify-full"
    BLOB_ACCOUNT   = azurerm_storage_account.blob.name
    BLOB_CONTAINER = azurerm_storage_container.jobs.name
    # La aplicacion debe obtener tokens MI; no son contrasenas ni cadenas con clave.
    AUTH_MODE = "managed_identity"
  }
  tags       = local.tags
  depends_on = [azurerm_subnet_network_security_group_association.lab]
}
resource "azurerm_postgresql_flexible_server" "db" {
  name                          = "pg-${local.suffix}"
  location                      = azurerm_resource_group.lab.location
  resource_group_name           = azurerm_resource_group.lab.name
  version                       = "16"
  sku_name                      = var.postgres_sku
  storage_mb                    = 32768
  backup_retention_days         = 7
  public_network_access_enabled = false
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = var.tenant_id
  }
  tags = local.tags
}
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "admin" {
  server_name         = azurerm_postgresql_flexible_server.db.name
  resource_group_name = azurerm_resource_group.lab.name
  tenant_id           = var.tenant_id
  object_id           = var.entra_admin_object_id
  principal_name      = var.entra_admin_login
  principal_type      = "User"
}
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "ineo"
  server_id = azurerm_postgresql_flexible_server.db.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
resource "azurerm_storage_account" "blob" {
  name                            = "st${var.project}${random_string.unique.result}"
  location                        = azurerm_resource_group.lab.location
  resource_group_name             = azurerm_resource_group.lab.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  public_network_access_enabled   = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}
resource "azurerm_storage_container" "jobs" {
  name                  = "jobs"
  storage_account_id    = azurerm_storage_account.blob.id
  container_access_type = "private"
}
resource "azurerm_private_endpoint" "postgres" {
  name                = "pe-postgres-${local.suffix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  subnet_id           = azurerm_subnet.lab["db"].id
  private_service_connection {
    name                           = "psc-postgres"
    private_connection_resource_id = azurerm_postgresql_flexible_server.db.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
  ip_configuration {
    name               = "postgres"
    private_ip_address = "10.0.2.4"
    subresource_name   = "postgresqlServer"
    member_name        = "postgresqlServer"
  }
  private_dns_zone_group {
    name                 = "postgres"
    private_dns_zone_ids = [azurerm_private_dns_zone.lab["postgres"].id]
  }
  tags = local.tags
}
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${local.suffix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  subnet_id           = azurerm_subnet.lab["endpoints"].id
  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.blob.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  ip_configuration {
    name               = "blob"
    private_ip_address = "10.0.4.4"
    subresource_name   = "blob"
    member_name        = "blob"
  }
  private_dns_zone_group {
    name                 = "blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.lab["blob"].id]
  }
  tags = local.tags
}
