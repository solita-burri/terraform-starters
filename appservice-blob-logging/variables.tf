variable "key_vault_name" {
  type        = string
  description = "Existing keyvault where secrets are stored"
}

variable "resource_group_name" {
  type        = string
  description = "Target resource group"
}

variable "location" {
  type        = string
  description = "Target region"
}

variable "application_name" {
  type    = string
  default = "demoapp"
}

variable "environment" {
  type    = string
  default = "dev"
}



