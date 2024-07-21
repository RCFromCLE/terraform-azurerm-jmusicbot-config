################################### variable block ####################################
terraform {
  cloud {
    organization = "RCHomeLab"
    workspaces {
      name = "azure-jmusicbot-kv"
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
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
}
################################### data block ####################################
data "azurerm_client_config" "current" {}
################################### resource blocks ####################################
resource "azurerm_resource_group" "kv_rg" {
  name     = var.kv_resource_group_name
  location = var.location
}
resource "azurerm_key_vault" "jdiscord_kv" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.kv_rg.location
  resource_group_name        = azurerm_resource_group.kv_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"
  enable_rbac_authorization  = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
      "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers", "Purge"
    ]
  }
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.additional_access_policy_object_id
    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
      "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers", "Purge"
    ]
  }
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "75c3ec5f-7cc1-4063-b92f-8a486fee1b25"
    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
      "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers", "Purge"
    ]
  }
}
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
locals {
  pem_public_key = tls_private_key.this.public_key_pem
  ssh_public_key = replace(trimspace(local.pem_public_key), "/^(-----(BEGIN|END) PUBLIC KEY-----|\n)//gm", "")
  openssh_public_key = "ssh-rsa ${local.ssh_public_key}"
}
resource "azurerm_key_vault_secret" "private_key" {
  name         = "ssh-private-key"
  value        = tls_private_key.this.private_key_pem
  key_vault_id = azurerm_key_vault.jdiscord_kv.id
}
resource "azurerm_key_vault_secret" "public_key" {
  name         = "ssh-public-key"
  value        = local.openssh_public_key
  key_vault_id = azurerm_key_vault.jdiscord_kv.id
}
resource "azurerm_key_vault_secret" "discord_bot_token" {
  name         = "discord-bot-token"
  value        = var.discord_bot_token
  key_vault_id = azurerm_key_vault.jdiscord_kv.id
}
resource "azurerm_key_vault_secret" "discord_bot_owner" {
  name         = "discord-bot-owner"
  value        = var.discord_bot_owner
  key_vault_id = azurerm_key_vault.jdiscord_kv.id
}
resource "azurerm_key_vault_secret" "discord_bot_prefix" {
  name         = "discord-bot-prefix"
  value        = var.discord_bot_prefix
  key_vault_id = azurerm_key_vault.jdiscord_kv.id
}
################################### output blocks ####################################
output "key_vault_name" {
  value = azurerm_key_vault.jdiscord_kv.name
}
output "key_vault_id" {
  value = azurerm_key_vault.jdiscord_kv.id
}
output "public_key_secret_name" {
  value = azurerm_key_vault_secret.public_key.name
}