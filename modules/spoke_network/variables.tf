variable "vnet_name" {}
variable "location" {}
variable "resource_group_name" {}
variable "vnet_cidr" {}
variable "subnet_cidr" {}
variable "enable_webapp_delegation" {
  type    = bool
  default = false
}
variable "firewall_private_ip" {
  description = "The private IP of the Hub Firewall for UDR enforcement"
  type        = string
  default     = null
}
