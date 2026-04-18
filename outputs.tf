##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "server_name" {
  description = "The name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "server_id" {
  description = "The ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "resource_group_name" {
  description = "The resource group name where the server was deployed."
  value       = azurerm_resource_group.this.name
}

output "database_name" {
  description = "The initial database name."
  value       = azurerm_postgresql_flexible_server_database.initial.name
}

output "administrator_login" {
  description = "The administrator login username."
  value       = local.admin_login
}

output "credentials_secret_name" {
  description = "The Azure Key Vault secret name storing the master credentials JSON."
  value       = azurerm_key_vault_secret.master_credentials.name
}
