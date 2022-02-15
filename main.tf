# Creating Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan

    content {
      id     = ddos_protection_plan.value["ddos_protection_plan_id"]
      enable = ddos_protection_plan.value["enable_ddos_protection_plan"]
    }
  }
}


# Creating Subnets
resource "azurerm_subnet" "subnet" {
  for_each                                       = var.subnets
  name                                           = lookup(each.value, "subnet_name", lower("snet-${each.key}"))
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = each.value.subnet_address_prefixes
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

# Creating Network Security Group based on input from nsg attribute in each subnet
# Only created if nsg is true - default is false

resource "azurerm_network_security_group" "nsg" {
  for_each = {
    for k in keys(var.subnets) :
    k => var.subnets[k]
    if lookup(var.subnets[k], "nsg", "false")
  }

  # Name can be overwritten with nsg_name or using the subnet name minus snet-
  name                = lookup(each.value, "nsg_name", lower("nsg-${trimprefix(azurerm_subnet.subnet["${each.key}"].name, "snet-")}"))
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dynamic "security_rule" {
    for_each = concat(lookup(each.value, "nsg_inbound_rules", []), lookup(each.value, "nsg_outbound_rules", []))

    content {
      name                                       = try(security_rule.value.name, null)
      priority                                   = try(security_rule.value.priority, null)
      direction                                  = try(security_rule.value.direction, null)
      access                                     = try(security_rule.value.access, null)
      protocol                                   = try(security_rule.value.protocol, null)
      source_port_range                          = try(security_rule.value.source_port_range, null)
      source_port_ranges                         = try(security_rule.value.source_port_ranges, null)
      destination_port_range                     = try(security_rule.value.destination_port_range, null)
      destination_port_ranges                    = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix                      = try(security_rule.value.source_address_prefix == each.key ? element(each.value.subnet_address_prefix, 0) : security_rule.value.source_address_prefix, null)
      source_address_prefixes                    = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefix                 = try(security_rule.value.destination_address_prefix == each.key ? element(each.value.subnet_address_prefix, 0) : security_rule.value.destination_address_prefix, null)
      destination_address_prefixes               = try(security_rule.value.destination_address_prefixes, null)
      source_application_security_group_ids      = try(security_rule.value.source_application_security_group_ids, null)
      destination_application_security_group_ids = try(security_rule.value.destination_application_security_group_ids, null)
      description                                = try(security_rule.value.description, null)
    }
  }
}

# Associating Network Security group with the subnet based on NSG creation.
resource "azurerm_subnet_network_security_group_association" "nsg" {
  for_each = {
    for k in keys(var.subnets) :
    k => var.subnets[k]
    if lookup(var.subnets[k], "nsg", "false")
  }

  network_security_group_id = azurerm_network_security_group.nsg["${each.key}"].id
  subnet_id                 = azurerm_subnet.subnet["${each.key}"].id
}

# Creating Route Table based on input from route_table attribute in each subnet
# Only created if route_table is true - default is false

resource "azurerm_route_table" "rt" {
  for_each = {
    for k in keys(var.subnets) :
    k => var.subnets[k]
    if lookup(var.subnets[k], "route_table", "false")
  }
  # Name can be overwritten with route_table_name or using the subnet name minus snet-
  name                          = lookup(each.value, "route_table_name", lower("rt-${trimprefix(azurerm_subnet.subnet["${each.key}"].name, "snet-")}"))
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tags                          = var.tags
  disable_bgp_route_propagation = lookup(each.value, "disable_bgp_route_propagation", "false")

  dynamic "route" {
    for_each = lookup(each.value, "routes", [])

    content {
      address_prefix         = route.value.address_prefix
      name                   = route.value.name
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_type == "VirtualAppliance" ? route.value.next_hop_in_ip_address : null
    }
  }
}

# Associating RouteTable with the subnet based on RouteTable creation.
resource "azurerm_subnet_route_table_association" "rt" {
  for_each = {
    for k in keys(var.subnets) :
    k => var.subnets[k]
    if lookup(var.subnets[k], "route_table", "false")
  }

  route_table_id = azurerm_route_table.rt["${each.key}"].id
  subnet_id      = azurerm_subnet.subnet["${each.key}"].id
}