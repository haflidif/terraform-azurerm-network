terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.90.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "<Your Remote Backend Resource group Name>"
    storage_account_name = "<Remote Backend Storage Account Name>"
    container_name       = "<Remote Backend Container Name>"
    subscription_id      = "<Subscription ID>"
    use_azuread_auth     = true # Using Azure AD Authentication (Make sure the user| service principal| Managed Identity has Storage Blob Contributior rights)
    key                  = "<Remote State file name>"
  }
}

provider "azurerm" {
  subscription_id = "<Subscription ID>"

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

resource "random_id" "rg" {
  byte_length = 8
}

resource "azurerm_resource_group" "test" {
  name     = "rg-network-test-${random_id.rg.hex}"
  location = "norwayeast"
}

module "network" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test.name
  location            = "norwayeast"
  vnet_name           = "vnet-complete-test"
  vnet_address_space  = ["10.0.0.0/23"]
  dns_servers         = []

  tags = {
    "Environment" = "Test"
  }

  ddos_plan      = true
  ddos_plan_name = "AzureDdosPlan1"

  subnets = {
    subnet1 = {
      subnet_name                                    = "subnet1"
      subnet_address_prefix                          = ["10.0.0.0/24"]
      service_endpoints                              = ["Microsoft.Storage"]
      enforce_private_link_endpoint_network_policies = true
      delegation = [{
        name         = "delegation1"
        service_name = "Microsoft.ContainerInstance/containerGroups"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        },
        {
          name         = "delegation2"
          service_name = "Microsoft.ContainerInstance/containerGroups"
          actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }]
    }
  }
}