variable "location" {}
variable "resource_group_name" {}
variable "firewall_subnet_id" {}
variable "waf_subnet_id" {}
variable "law_id" {}
variable "unique_id" {}
variable "backend_ips" {
  type    = list(string)
  default = []
}
variable "backend_fqdns" {
  type    = list(string)
  default = []
}
