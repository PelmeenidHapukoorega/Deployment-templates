output "storage_account_id" {
  value = module.storage.storage_account_id
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "primary_blob_endpoint" {
  value = module.storage.primary_blob_endpoint
}

output "container_ids" {
  value = module.storage.container_ids
}

output "identity_principal_id" {
  value = module.security.identity_principal_id
}