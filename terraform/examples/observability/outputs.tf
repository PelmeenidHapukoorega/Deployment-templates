output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "workspace_id" {
  value = module.observability.workspace_id
}

output "workspace_name" {
  value = module.observability.workspace_name
}

output "action_group_id" {
  value = module.observability.action_group_id
}