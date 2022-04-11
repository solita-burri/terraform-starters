variable "location" {
  default = "westeurope"
}
variable "resource_group_name" {

}
variable "tenant_id" {

}
variable "cidr_blocks_whitelist" {
  type        = list(any)
  description = "CIDR Blocks for whitelisting traffic"
}
variable "developer_id" {
  description = "value"
}
variable "project" {
  default = "demo"
}
variable "environment" {
  default = "dev"
}
