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

module "security" {
  source = "../../modules/security"

  prefix = var.prefix
  location = var.location
  resource_group_name = azurerm_resource_group.this.name

  enable_key_vault = true
  key_vault_sku = "standard"

  tags = {
    Environment = "test"
    Project = "Security-module-example"
  }
}