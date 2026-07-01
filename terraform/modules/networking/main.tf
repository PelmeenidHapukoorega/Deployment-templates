resource "azurerm_virtual_network" "this" {
  name = "${var.prefix}-vnet"
  location = var.location
  resource_group_name = var.resource_group_name
  address_space = var.vnet_address_space
  tags = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = { for s in var.subnets : s.name => s }

  name = each.value.name
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes = each.value.address_prefixes
}

resource "azurerm_network_security_group" "this" {
  name = "${var.prefix}-nsg"
  location = var.location
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_network_security_rule" "http" {
  count = var.enable_http ? 1 : 0

  name = "allow-http"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "80"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "https" {
  count = var.enable_https ? 1 : 0

  name = "allow-https"
  priority = 110
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "443"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "management" {
  count = var.management_allowed_cidr != null ? 1: 0

  name = "allow-management"
  priority = 120
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_ranges = var.management_ports
  source_address_prefix = var.management_allowed_cidr
  destination_address_prefix = "*"
  resource_group_name = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  name = "deny_all_inbound"
  priority = 4096
  direction = "Inbound"
  access = "Deny"
  protocol = "*"
  source_port_range = "*"
  destination_port_range = "*"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = azurerm_subnet.this

  subnet_id = each.value.id 
  network_security_group_id = azurerm_network_security_group.this.id
}