################################### terraform block ####################################
terraform {
    cloud {
    organization = "RCHomeLab"
    workspaces {
      name = "azure-jmusicbot"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}

################################### provider block ####################################
provider "azurerm" {
  features {}
  subscription_id = var.sub
}
#################################### module block ###################################

