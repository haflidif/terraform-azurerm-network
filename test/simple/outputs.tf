output "vnet_name" {
  value = module.network.virtual_network_name
}

output "vnet_id" {
  value = module.network.virtul_network_id
}

output "vnet_address_space" {
  value = module.network.virtual_network_address_space
}

output "vnet_subnets" {
  value = module.network.virtual_network_subnets
}

output "nsg" {
  value = module.network.network_security_groups
}

output "route_tables" {
  value = module.network.route_tables
}