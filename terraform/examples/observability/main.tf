terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "this" {
  name = "${var.prefix}-rg"
  location = var.location
}

module "networking" {
  source = "../../modules/networking"

  prefix = var.prefix
  location = var.location
  resource_group_name = azurerm_resource_group.this.name

  subnets = [
    { name = "default", address_prefixes = ["10.0.1.0/24"] }
  ]

  management_allowed_cidr = var.my_ip != "" ? "${var.my_ip}/32" : null
}

resource "azurerm_public_ip" "vm" {
  name = "${var.prefix}-vm-ip"
  location = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_network_interface" "vm" {
  name = "${var.prefix}-vm-nic"
  location = var.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name = "internal"
    subnet_id = module.networking.subnet_ids["default"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "${var.prefix}-vm"
  location = var.location
  resource_group_name = azurerm_resource_group.this.name
  size = "Standard_D2as_v6"
  admin_username = "azureuser"

  network_interface_ids = [azurerm_network_interface.vm.id]

  admin_ssh_key {
    username = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-jammy"
    sku = "22_04-lts-gen2"
    version = "latest"
  }
}

module "observability" {
  source = "../../modules/observability"

  prefix = var.prefix
  location = var.location
  resource_group_name = azurerm_resource_group.this.name

  diagnostic_targets = [azurerm_linux_virtual_machine.vm.id]
  alert_targets = [azurerm_linux_virtual_machine.vm.id]
  enable_log_category = false

  alert_email = var.alert_email

  tags = {
    Environment = "Test"
    Project = "observability-module-example"
  }
}