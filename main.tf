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

################################### provider block ###################################
provider "azurerm" {
  features {}
  subscription_id = var.sub
}
################################### module block ##################################
module "jmusicbot" {
  source  = "RCFromCLE/jmusicbot/azure"
  version = "1.2.3"

  # required variables
  azure_tenant_id     = var.azure_tenant_id
  sub                 = var.sub
  discord_bot_token   = var.discord_bot_token
  discord_bot_owner   = var.discord_bot_owner
  general_channel_id  = var.general_channel_id
  music_channel_id    = var.music_channel_id
  afk_channel_id      = var.afk_channel_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret

  # optional variables
  rg                 = var.rg
  rg_loc             = var.rg_loc
  net                = var.net
  subnet             = var.subnet
  pub_ip             = var.pub_ip
  nic_name           = var.nic_name
  nsg                = var.nsg
  vm_name            = var.vm_name
  vm_size            = var.vm_size
  ssh_public_key     = data.azurerm_key_vault_secret.ssh_public_key.value
  ssh_private_key    = data.azurerm_key_vault_secret.ssh_private_key.value
  vm_image_publisher = var.vm_image_publisher
  vm_image_offer     = var.vm_image_offer
  vm_image_sku       = var.vm_image_sku
  vm_image_version   = var.vm_image_version
  os_disk_name       = var.os_disk_name
  vm_admin_username  = var.vm_admin_username
}