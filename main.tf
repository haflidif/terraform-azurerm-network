# Creating Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_plan == true ? [1] : [0]

    content {
      id     = azurerm_network_ddos_protection_plan.ddos[0].id
      enable = true
    }
  }
}

# Creating ddos protection plan if var.ddos_plan is true, default is false
resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.ddos_plan ? 1 : 0
  name                = var.ddos_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Creating Subnets
resource "azurerm_subnet" "subnet" {
  for_each                                       = var.subnets
  name                                           = each.value.subnet_name
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = each.value.subnet_address_prefix
  service_endpoints                              = lookup(each.value, "service_endpoints", [])
  enforce_private_link_endpoint_network_policies = lookup(each.value, "enforce_private_link_endpoint_network_policies", null)
  enforce_private_link_service_network_policies  = lookup(each.value, "enforce_private_link_service_network_policies", null)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", [])
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}