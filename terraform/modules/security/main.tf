data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "this" {
  name = "${var.prefix}-identity"
  location = var.location
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_key_vault" "this" {
  count = var.enable_key_vault ? 1 : 0

  name = "${var.prefix}-kv"
  location = var.location
  resource_group_name = var.resource_group_name
  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name = var.key_vault_sku
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled = true
  tags = var.tags
}

resource "azurerm_role_assignment" "identity_kv_secrets_user" {
  count = var.enable_key_vault ? 1 : 0

  scope = azurerm_key_vault.this[0].id 
  role_definition_name = "Key Vault Secrets User"
  principal_id = azurerm_user_assigned_identity.this.principal_id
}