variable "vnet_name" {}
variable "location" {}
variable "resource_group_name" {}
variable "vnet_cidr" {}
variable "subnet_cidr" {}
variable "enable_webapp_delegation" {
  type    = bool
  default = false
}
