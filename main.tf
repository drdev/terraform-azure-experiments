terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.59.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

