
terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.74.0"
    }
    local = {
      source = "hashicorp/local"
      version = "=2.1.0"
    }
    random = {
      source = "hashicorp/random"
      version = "=3.1.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "=3.1.0"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}
