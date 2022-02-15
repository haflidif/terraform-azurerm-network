variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where resources should be deployed."
}

variable "location" {
  type        = string
  description = "Region / Location"
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

variable "ddos_protection_plan" {
  description = "Configures DDos Protection Plan on the Virtual Network"
  type = set(object(
    {
      ddos_protection_plan_id     = string
      enable_ddos_protection_plan = bool
    }
  ))
  default = []
}

variable "subnets" {
  description = "A block to define one or more subnets within the module."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Resource tagging"
  default     = {}
}