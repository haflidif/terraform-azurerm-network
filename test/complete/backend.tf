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