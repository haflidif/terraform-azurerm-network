provider "azurerm" {
  subscription_id = "<Subscription ID>"

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # Set this to true if you want to prevent resource group deletion when there are other resources in the RG: This will be default to true in azurerm provider version 3.0
      prevent_deletion_if_contains_resources = false
    }
  }
}