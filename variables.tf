variable "subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "The Azure Tenant ID"
  type        = string
}

variable "location_primary" {
  description = "Primary Region (Hub)"
  type        = string
  default     = "uksouth"
}

variable "location_dr" {
  description = "Disaster Recovery Region"
  type        = string
  default     = "ukwest"
}

variable "hub_vnet_cidr" {
  description = "CIDR block for the Hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "firewall_subnet_cidr" {
  description = "CIDR for AzureFirewallSubnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "gateway_subnet_cidr" {
  description = "CIDR for GatewaySubnet (VPN/ExpressRoute)"
  type        = string
  default     = "10.0.0.0/24"
}

variable "app_gateway_subnet_cidr" {
  description = "CIDR for Application Gateway"
  type        = string
  default     = "10.0.2.0/24"
}

variable "workload_subnet_cidr" {
  description = "CIDR for Shared Services/Workload"
  type        = string
  default     = "10.0.10.0/24"
}
