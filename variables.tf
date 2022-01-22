variable "resource_group_name" {
  type = string
  description = ""
}

variable "location" {
  type = string
  description = ""
}

variable "vnet_name" {
  type = string
  description = ""
}

variable "vnet_address_space" {
  type = list(string)
  description = ""
}

variable "dns_servers" {
  type = list(string)
  description = ""
  default = []
}

variable "ddos_plan" {
  type = bool
  description = ""
  default = false
}

variable "subnets" {
  default = {}
}

variable "delegation" {
  description = "Subnet Delegation configuration"
  type = list(object({
    name         = string
    service_name = string
    actions      = list(string)
  }))
  default = []
}
