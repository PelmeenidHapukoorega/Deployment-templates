output "vnet_id" {
  description = "ID of the created virtual network"
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the created VNet"
  value = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "nsg_id" {
    description = "ID of the NSG"
    value = azurerm_network_security_group.this.id
}