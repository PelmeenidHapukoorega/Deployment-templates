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

  vnet_address_space = ["10.0.0.0/16"]

  subnets = [
    {
        name = "web"
        address_prefixes = ["10.0.1.0/24"]
    },
    {
        name = "data"
        address_prefixes = ["10.0.2.0/24"]
    }
  ]

  enable_http = true
  enable_https = true
  management_allowed_cidr = var.my_ip != null ? "${var.my_ip}/32" : null

  tags = {
    Environment = "Test"
    Project = "networking-module-example"
  }
}