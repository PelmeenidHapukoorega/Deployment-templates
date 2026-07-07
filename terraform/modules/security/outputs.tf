output "identity_id" {
  description = "Resource ID of user assigned managed identity"
  value = azurerm_user_assigned_identity.this.id
}

output "identity_principal_id" {
  description = "Principal ID of the MI, used when granting it access to other resources"
  value = azurerm_user_assigned_identity.this.principal_id
}

output "identity_client_id" {
  description = "Client ID of the MI, used by app code to request tokens"
  value = azurerm_user_assigned_identity.this.client_id
}

output "key_vault_id" {
  description = "Resource ID of the KV, if created"
  value = var.enable_key_vault ? azurerm_key_vault.this[0].vault_uri : null
}

output "key_vault_uri" {
  description = "URI of the KV, if created"
  value = var.enable_key_vault ? azurerm_key_vault.this[0].vault_uri : null
}