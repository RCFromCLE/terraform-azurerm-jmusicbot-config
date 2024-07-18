variable "subscription_id" {
  description = "The subscription ID"
  type        = string
}

variable "location" {
  description = "The location for the Key Vault"
  type        = string
  default     = "East US"
}

variable "kv_resource_group_name" {
  description = "The name of the resource group for the Key Vault"
  type        = string
}

variable "key_vault_name" {
  description = "The name of the Key Vault"
  type        = string
}

variable "discord_bot_token" {
  description = "The Discord bot token"
  type        = string
  sensitive   = true
}

variable "discord_bot_owner" {
  description = "The Discord bot owner ID"
  type        = string
}

variable "discord_bot_prefix" {
  description = "The Discord bot command prefix"
  type        = string
}

variable "additional_access_policy_object_id" {
  description = "Additional object ID for Key Vault access policy"
  type        = string
}