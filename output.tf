output "virtual_network_name" {
  description = "The name of the virtual network."
  value       = azurerm_virtual_network.vnet.name
}

output "virtul_network_id" {
  description = "The virtual network id"
  value       = azurerm_virtual_network.vnet.id
}

output "virtual_network_address_space" {
  description = "List of address spaces that are used in the virtual network"
  value       = azurerm_virtual_network.vnet.address_space
}
output "virtual_network_subnets" {
  description = "Maps out virtual network subnets created with names and ids"
  value = tomap({
    for k, subnet in azurerm_subnet.subnet : k => { id : subnet.id, name : subnet.name, address_prefixes : subnet.address_prefixes }
  })
}

output "network_security_groups" {
  description = "Maps out created network security groups (NSG) and provides name and id for each."
  value = tomap({
    for k, nsg in azurerm_network_security_group.nsg : k => { id : nsg.id, name : nsg.name }
  })
}

output "route_tables" {
  description = "Maps out created route tables and provides name and id for each route table"
  value = tomap({
    for k, rt in azurerm_route_table.rt : k => { id : rt.id, name : rt.name }
  })
}
