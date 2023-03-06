variable "org_id" {
  type        = string
  description = "Organisation ID"
}

variable "hub_spoke_id" {
  type        = string
  description = "Hub & Spoke ID"
  default     = "h01s01"
}

variable "service" {
  type        = string
  description = "Service abbreviation"
}

variable "environment" {
  type        = string
  description = "What environment, e.g. nonprod, prod.e"
}

variable "location" {
  type        = string
  description = "Location for all Azure resources"
}

variable "rg_name" {
  type = string
}

variable "admin_object_id" {
  type = string
}

variable "db_admin_username" {
  type = string
}

variable "db_sku" {
  type    = string
  default = "GP_S_Gen5_1"
}

variable "shir_username" {
  type = string
}

variable "network_config" {
  type        = map(any)
  description = "Vnet & subnet information"
}

variable "cmk_size" {
  type    = number
  default = 2048
}
variable "cmk_type" {
  type    = string
  default = "RSA"
}
variable "cmk_opts" {
  type = list(any)
  default = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

variable "shir_sku" {
  type        = string
  description = "SKU for the Self Hosted Integration Runtime"
  default     = "Standard_D4as_v5"
}