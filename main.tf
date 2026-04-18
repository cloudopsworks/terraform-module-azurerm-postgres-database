##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  server_name   = try(var.settings.name_prefix, "") != "" ? "${local.system_name_short}-${var.settings.name_prefix}" : local.system_name_short
  database_name = try(var.settings.database_name, "postgres")
  admin_login   = try(var.settings.administrator_login, "adminuser")
}

resource "azurerm_resource_group" "this" {
  name     = "${local.system_name}-postgres-rg"
  location = var.region
  tags     = local.all_tags
}

resource "random_password" "master" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = local.server_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  version                       = var.settings.version
  sku_name                      = var.settings.sku_name
  storage_mb                    = try(var.settings.storage_mb, 32768)
  storage_tier                  = try(var.settings.storage_tier, null)
  backup_retention_days         = try(var.settings.backup_retention_days, 7)
  geo_redundant_backup_enabled  = try(var.settings.geo_redundant_backup, false)
  zone                          = try(var.settings.zone, null)
  create_mode                   = try(var.settings.create_mode, "Default")
  administrator_login           = local.admin_login
  administrator_password        = random_password.master.result
  delegated_subnet_id           = try(var.network.delegated_subnet_id, null)
  private_dns_zone_id           = try(var.network.private_dns_zone_id, null)
  public_network_access_enabled = try(var.network.public_network_access, true)
  tags                          = local.all_tags

  dynamic "high_availability" {
    for_each = try(var.settings.high_availability.enabled, false) ? [1] : []
    content {
      mode                      = try(var.settings.high_availability.mode, "ZoneRedundant")
      standby_availability_zone = try(var.settings.high_availability.standby_zone, null)
    }
  }

  maintenance_window {
    day_of_week  = try(var.settings.maintenance.day_of_week, 0)
    start_hour   = try(var.settings.maintenance.start_hour, 0)
    start_minute = try(var.settings.maintenance.start_minute, 0)
  }
}

resource "azurerm_postgresql_flexible_server_database" "initial" {
  name      = local.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "additional" {
  for_each  = try(var.settings.databases, {})
  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = try(each.value.charset, "UTF8")
  collation = try(each.value.collation, "en_US.utf8")
}

resource "azurerm_postgresql_flexible_server_configuration" "params" {
  for_each  = { for p in try(var.settings.parameters, []) : p.name => p }
  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = each.value.value
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "this" {
  for_each         = { for r in try(var.network.firewall_rules, []) : r.name => r }
  name             = each.value.name
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}
