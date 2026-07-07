output "storage_account_id" {
  description = "Resource ID for ST account"
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of ST account"
  value = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint url"
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "container_ids" {
  description = "Map of container name to container resource manager ID"
  value = { for name, container in azurerm_storage_container.this : name => container.id }
}