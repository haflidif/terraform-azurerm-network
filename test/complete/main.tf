# Creating Random id to append to the resource group name
resource "random_id" "rg" {
  byte_length = 8
}

resource "azurerm_resource_group" "test" {
  name     = "rg-network-test-${random_id.rg.hex}"
  location = "westeurope"
}

# Creating ddos protection plan if var.ddos_plan is true, default is false
resource "azurerm_network_ddos_protection_plan" "ddos" {
  name                = "ddos-westeurope-${random_id.rg.hex}"
  resource_group_name = azurerm_resource_group.test.name
  location            = "westeurope"
  tags = {
    ProjectName  = "Platform-Demo"
    Environment  = "dev"
    Owner        = "user@corp.com"
    BusinessUnit = "CORP"
    CostCenter   = "IT"
    ServiceClass = "Dev"
  }
}

module "network" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test.name
  location            = "westeurope"
  vnet_name           = "vnet-test-${random_id.rg.hex}"
  vnet_address_space  = ["10.0.0.0/23"]
  dns_servers         = []

  tags = {
    ProjectName  = "Platform-Demo"
    Environment  = "dev"
    Owner        = "user@corp.com"
    BusinessUnit = "CORP"
    CostCenter   = "IT"
    ServiceClass = "Dev"
  }

  ddos_protection_plan = [{
    ddos_protection_plan_id     = azurerm_network_ddos_protection_plan.ddos.id
    enable_ddos_protection_plan = true
  }]

  subnets = {

    # Subnet 1
    #  - NSG with Inbound and Outbound rules
    #  - RouteTable with two routes.

    subnet1 = {
      subnet_name                                    = "snet-web-westeurope-001"
      subnet_address_prefixes                        = ["10.0.0.0/24"]
      service_endpoints                              = ["Microsoft.Storage"]
      enforce_private_link_endpoint_network_policies = true

      # Creating NSG
      #  - To create empty NSG with default rules, only specify nsg = true
      nsg = true

      # Specifying NSG Inbound Rules
      nsg_inbound_rules = [
        {
          name                       = "AllowHTTPSInbound"
          description                = "Allowing HTTPS Inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "TCP"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "VirtualNetwork"
        }
      ]

      # Specifying NSG Outbound Rules
      nsg_outbound_rules = [
        {
          name                       = "AllowStorageOutbound"
          description                = "Allowing Outbound access to Azure Storage"
          priority                   = 4020
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "TCP"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "Storage"
        },
        {
          name                       = "DenyInternetOutbound"
          priority                   = 4096
          direction                  = "Outbound"
          access                     = "Deny"
          protocol                   = "TCP"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "Internet"
        }
      ]

      # Creating RouteTable
      # - To Create Empty RouteTable only specify route_table = true
      route_table = true

      # Specifying Routes
      routes = [{
        name                   = "test"
        address_prefix         = "10.0.0.0/24"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.2.10"
        },
        {
          name           = "test2"
          address_prefix = "52.32.152.22/32"
          next_hop_type  = "Internet"
      }]
    }

    # Subnet 2
    #  - With Delegation

    subnet2 = {
      subnet_name             = "snet-containers-westeurope-001"
      subnet_address_prefixes = ["10.0.1.0/25"]
      delegation = [
        {
          name         = "container_group_delegation"
          service_name = "Microsoft.ContainerInstance/containerGroups"
          actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      ]
    }

    # Subnet 3
    # - With empty NSG (Default Rules only)
    # - With empty RouteTable

    subnet3 = {
      subnet_name             = "snet-app-westeurope-001"
      subnet_address_prefixes = ["10.0.1.128/25"]
      nsg                     = true
      route_table             = true
    }
  }
}