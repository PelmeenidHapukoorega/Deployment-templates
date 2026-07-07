resource "azurerm_storage_account" "this" {
  name = "${var.prefix}sa${substr(md5(var.resource_group_name), 0, 6)}"
  location = var.location
  resource_group_name = var.resource_group_name

  account_tier = "Standard"
  account_replication_type = var.account_replication_type
  access_tier = var.access_tier

  https_traffic_only_enabled = true
  min_tls_version = "TLS1_2"
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each = toset(var.containers)

  name = each.value
  storage_account_id = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "identity_access" {
  for_each = { for idx, principal_id in var.identity_principal_ids_with_access : tostring(idx) => principal_id }

  scope = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = each.value
}