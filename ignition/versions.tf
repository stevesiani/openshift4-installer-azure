terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.74.0"
    }
    ignition = {
      source = "community-terraform-providers/ignition"
    }
    local = {
      source = "hashicorp/local"
      version = "=2.1.0"
    }
    null = {
      source = "hashicorp/null"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}
