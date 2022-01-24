variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where resources should be deployed."
}

variable "location" {
  type        = string
  description = "Region"
}

variable "vnet_name" {
  type        = string
  description = "Virtual Network Name"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "List of all virtual network addresses"
}

variable "dns_servers" {
  type        = list(string)
  description = "List to define Custom DNS Servers"
  default     = []
}

variable "ddos_plan" {
  type        = bool
  description = "A boolean to define if the Virtual Network should have DDos Plan Available"
  default     = false
}

variable "ddos_plan_name" {
  type        = string
  description = "DDos Plan Name"
  default     = "AzureDdosPlan1"
}

variable "subnets" {
  type        = map(any)
  description = "A block to define one or more subnets within the module."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Resource tagging"
  default     = {}
}