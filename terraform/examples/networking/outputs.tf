output "vnet_id" {
  value = module.networking.vnet_id
}

output "vnet_name" {
  value = module.networking.vnet_name
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}

output "nsg_id" {
  value = module.networking.nsg_id
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}