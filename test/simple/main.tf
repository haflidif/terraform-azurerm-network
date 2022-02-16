# Creating Random id to append to the resource group name
resource "random_id" "rg" {
  byte_length = 8
}

resource "azurerm_resource_group" "test" {
  name     = "rg-network-test-${random_id.rg.hex}"
  location = "westeurope"
}

module "network" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test.name
  location            = "westeurope"
  vnet_name           = "vnet-test-${random_id.rg.hex}"
  vnet_address_space  = ["10.0.0.0/24"]
  tags = {
    ProjectName  = "Platform-Demo"
    Environment  = "dev"
    Owner        = "user@corp.com"
    BusinessUnit = "CORP"
    CostCenter   = "IT"
    ServiceClass = "Dev"
  }

  subnets = {

    # Subnet 1
    subnet1 = {
      subnet_name             = "snet-app-westeurope-001"
      subnet_address_prefixes = ["10.0.0.0/24"]
      nsg                     = true # Empty NSG
      route_table             = true # Empty Route Table
    }
  }
}