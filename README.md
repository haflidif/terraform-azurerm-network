# terraform-azurerm-network

Terraform Module to create basic Azure Network Resources with optional Subnet/s, NSG/s, Service delegation, service endpoints and route table/s

Type of resources that are supported within the module:

* [Virtual Network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)
* [Subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)
* [Subnet Service Delegation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet#delegation)
* [Virtual network service endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet#service_endpoints)
* [Private Link service / endpoint network policies for subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet#enforce_private_link_endpoint_network_policies)
* [Network Security Groups (NSG)](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group)
* [Route Tables](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table)

---

## Sample Usage

- __Resource Group__
- __Azure DDoS Protection Plan__
- __One set of vNet__
  -  Attaching DDos Protection __(This module does not create DDos Protection Plan)__
- Three sets of subnet
  - __Subnet 1__
    - With Service Endpoint to Microsoft Storage
    - With RouteTable and two routes
    - With NSG with one inbound and two outbound rules     
  - __Subnet 2__
    - With Delegation
    - No NSG
    - No RouteTable
  - __Subnet 3__
    - With empty NSG (Default Rules only)
    - With empty RouteTable


```hcl
resource "azurerm_resource_group" "shared_network_hub" {
  name     = "rg-shared-hub-westeurope-001"
  location = "westeurope"
}

# Creating ddos protection plan if var.ddos_plan is true, default is false
resource "azurerm_network_ddos_protection_plan" "westeu" {
  name                = "ddos-westeurope"
  resource_group_name = azurerm_resource_group.test.name
  location            = "westeurope"
  tags = {
    "Environment" = "Test"
  }
}


module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  # By default, this module does not create a resource group, provide the resource group name here

  resource_group_name = "rg-shared-network-westeurope-001"
  location            = "westeurope"
  vnet_name           = "vnet-shared-hub-westeurope-001"
  vnet_address_space  = ["10.0.0.0/23"]
  dns_servers         = [] # (Optional: Specify list of custom DNS servers) default is Azure provided DNS
    
  # (Optional: Attaching DDoS Plan to virtual network) - by default DDoS Protection plan is not attached.
  ddos_protection_plan = [{
    ddos_protection_plan_id = azurerm_network_ddos_protection_plan.ddos.id
    enable                  = true 
  }]

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups and RouteTable.
  # NSG association is added automatically for all subnets that specify NSG.
  # RouteTable association is added automatically for all subnets that specify RouteTable.

  subnets = {

    # Subnet 1
    subnet1 = {
      subnet_name                                    = "subnet1"
      subnet_address_prefix                          = ["10.0.0.0/24"]
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
    subnet2 = {
      subnet_name           = "subnet2"
      subnet_address_prefix = ["10.0.1.0/25"]
      delegation = [
        {
          name         = "container_group_delegation"
          service_name = "Microsoft.ContainerInstance/containerGroups"
          actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      ]
    }

    # Subnet 3
    subnet3 = {
      subnet_name           = "subnet3"
      subnet_address_prefix = ["10.0.1.128/25"]
      nsg                   = true
      route_table           = true
    }
  }
}
  
  # Adding Tag's to your Azure resources (Optional)
  tags = {
    ProjectName  = "test-shared-hub"
    Environment  = "test"
    Owner        = "user@corp.com"
    BusinessUnit = "IT-CORP"
    CostCenter   = "TestUnit"
  }
}
```
---
## Azure Network DDoS Protection Plan

By default, this module will not create or attach a DDoS Protection Plan to the Virtual Network. DDoS Protection Plan is limited to being created only once in every region (for now) so it didn't make sense to create it within the module. It is however possible to attach already created DDOs Plan outside of the module by defining the optional code below.

```hcl

# (Optional: Attaching DDoS Plan to virtual network) - by default DDoS Protection plan is not attached.
  ddos_protection_plan = [{
    ddos_protection_plan_id     = azurerm_network_ddos_protection_plan.ddos.id
    enable_ddos_protection_plan = true 
  }]
```
> *__Note:__ See Terraform documentation on how to create Azure DDos Protection Plan here: [AzureNetwork DDoS Protection Plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_ddos_protection_plan)*

## Custom DNS servers

This is an optional feature and only applicable if you are using your own DNS servers superseding default Azure provided DNS Servers. Set the argument `dns_servers = ["4.4.4.4"]` to enable this option. For multiple DNS servers, set the argument and provide comma seperated list of dns servers `dns_servers = ["4.4.4.4", "8.8.8.8"]`

## Subnets

This module handles the following types of subnet creation:

* __Subnets__ - add, change, or delete of subnet supported. The subnet name and address range must be unique within the address space for the virtual network. A subnet may optionally have one or more service endpoints enabled for it. To enable a service endpoint for a service, select the service or services that you want to enable service endpoints for from the Services list. A subnet may optionally have one or more delegations enabled for it. Subnet delegation gives explicit permissions to the service to create service-specific resources in the subnet using a unique identifier during service deployment. To delegate for a service, select the service you want to delegate to from the Services list.


## Virtual network service endpoints

__Service Endpoints__ allows connecting certain platform services into virtual networks.  With this option, Azure virtual machines can interact with Azure SQL and Azure Storage accounts, as if they’re part of the same virtual network, rather than Azure virtual machines accessing them over the public endpoint.

This module supports enabling the service endpoint of your choosing under the virtual network and with the specified subnet. The list of Service endpoints to associate with the subnet values include: `Microsoft.AzureActiveDirectory`, `Microsoft.AzureCosmosDB`, `Microsoft.ContainerRegistry`, `Microsoft.EventHub`, `Microsoft.KeyVault`, `Microsoft.ServiceBus`, `Microsoft.Sql`, `Microsoft.Storage` and `Microsoft.Web`

> *__Note:__ See complete list of supported service endpoints here: [Azure virtual network service endpoints](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview)*

```hcl
module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  #..omitted

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups and RouteTable.
  # NSG association is added automatically for all subnets that specify NSG.
  # RouteTable association is added automatically for all subnets that specify RouteTable.

   subnet1 = {
      subnet_name                                    = "subnet1"
      subnet_address_prefix                          = ["10.0.0.0/24"]
      service_endpoints                              = ["Microsoft.Storage"]  
    }

  #..omitted

}
```

## Subnet Service Delegation

This module supports enabling the service delegation of your choosing under the specified subnet.  For more information and see what Service Delegations are supported, check the [terraform resource documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet#service_delegation).


```hcl
module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  #..omitted

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups and RouteTable.
  # NSG association is added automatically for all subnets that specify NSG.
  # RouteTable association is added automatically for all subnets that specify RouteTable.

  subnets = {
    #..omitted

    subnet2 = {
      subnet_name           = "subnet2"
      subnet_address_prefix = ["10.0.1.0/25"]
      delegation = [
        {
          name         = "container_group_delegation"
          service_name = "Microsoft.ContainerInstance/containerGroups"
          actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      ]
    }
  }

  #..omitted
}
```

## Private Link Endpoint on the subnet - `enforce_private_link_endpoint_network_policies`

Network policies, like network security groups (NSG), are not yet fully supported [(In Public Preview in limited regions)](https://azure.microsoft.com/en-us/updates/public-preview-of-private-link-network-security-group-support/) for Private Link Endpoints. In order to deploy a Private Link Endpoint on a given subnet, you must set the `enforce_private_link_endpoint_network_policies` attribute to `true`. This setting is only applicable for the Private Link Endpoint, for all other resources in the subnet access is controlled based on the Network Security Group which can be configured using the `nsg = true` and specifying `nsg_inbound_rules` & `nsg_outbound_rules` resource in the module. 

In this module you can Enable or Disable network policies for the private link endpoint on the subnet. The default value is `false`. 
> *__Note:__ If you are enabling the Private Link Endpoints on the subnet you shouldn't use Private Link Services as it's conflicts.*

```hcl
module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  #..omitted

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups and RouteTable.
  # NSG association is added automatically for all subnets that specify NSG.
  # RouteTable association is added automatically for all subnets that specify RouteTable.

  subnets = {
    subnet1 = {
      subnet_name                                    = "subnet1"
      subnet_address_prefix                          = ["10.0.0.0/24"]
      enforce_private_link_endpoint_network_policies = true
      }
    }

  #..omitted
}
```

## Private link service on the subnet - `enforce_private_link_service_network_policies`

In order to deploy a Private Link Service on a given subnet, you must set the `enforce_private_link_service_network_policies` attribute to `true`. This setting is only applicable for the Private Link Service, for all other resources in the subnet access is controlled based on the Network Security Group which can be configured using the `nsg = true` and specifying `nsg_inbound_rules` & `nsg_outbound_rules` resource in the module.

In this module you can Enable or Disable network policies for the private link service on the subnet. The default value is `false`. 

> *__Note:__ If you are enabling the Private Link service on the subnet then, you shouldn't use Private Link endpoints as it's conflicts.*

```hcl
module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  #..omitted

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups and RouteTable.
  # NSG association is added automatically for all subnets that specify NSG.
  # RouteTable association is added automatically for all subnets that specify RouteTable.

  subnets = {
    subnet1 = {
      subnet_name                                   = "subnet1"
      subnet_address_prefix                         = ["10.0.0.0/24"]
      enforce_private_link_service_network_policies = true
      }
    }

  #..omitted

}
```
---
## Network Security Groups

By default, a network security group is __not__ created for the subnet, use `nsg = true` to create NSG for the specified `subnet` and use `nsg_inbound_rules` and `nsg_outbound_rules` in this module to create more specific rules for inbound and outbound flows.

In the Source and Destination columns, `VirtualNetwork`, `AzureLoadBalancer`, and `Internet` are service tags, rather than IP addresses. In the protocol column, Any encompasses `TCP`, `UDP`, and `ICMP` are allowed. When creating a rule, you can specify `TCP`, `UDP`, `ICMP` or `*`. `0.0.0.0/0` in the Source and Destination columns represents all addresses.


  > *__Note:__ If a Network security group (NSG) is created it will automatically be attached to the specific subnet.*
  
> *__Note:__ You cannot remove the default rules, but you can override them by creating rules with higher priorities.*

```hcl
module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  #..omitted

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups and RouteTable.
  # NSG association is added automatically for all subnets that specify NSG.
  # RouteTable association is added automatically for all subnets that specify RouteTable.

  subnets = {
    subnet1 = {
      subnet_name                                    = "subnet1"
      subnet_address_prefix                          = ["10.0.0.0/24"]

      # Creating NSG
       # To create empty NSG with default rules, only specify nsg = true
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
    
    #..omitted
    
    }
  }

#..omitted

}
```
---
## Route Table & Routes

```hcl
module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  #..omitted

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups and RouteTable.
  # NSG association is added automatically for all subnets that specify NSG.
  # RouteTable association is added automatically for all subnets that specify RouteTable.

  subnets = {
    subnet1 = {
      subnet_name                                    = "subnet1"
      subnet_address_prefix                          = ["10.0.0.0/24"]

      # Creating RouteTable
       # To Create Empty RouteTable only specify route_table = true
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
  }
#..omitted
}

```

---
## Recommended naming and tagging conventions

Well-defined naming and metadata tagging conventions help to quickly locate and manage resources. These conventions also help associate cloud usage costs with business teams via chargeback and show back accounting mechanisms.

### Resource naming

An effective naming convention assembles resource names by using important resource information as parts of a resource's name. For example, using these [recommended naming conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging#example-names), a public IP resource for a production azure firewall workload is named like this: `pip-azfirewall-prod-westeurope-001`.

> *__Note:__ Please keep in mind that there are restrictions and limitations on how Azure resources are named please reference to the: [Naming rules and restrictions for Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules)*

### Metadata tags

When applying metadata tags to the cloud resources, you can include information about those assets that couldn't be included in the resource name. You can use that information to perform more sophisticated filtering and reporting on resources. This information can be used by IT or business teams to find resources or generate reports about resource usage and billing.

The following list provides good recommendation on common tags that capture important context and information about resources. Use this list as a starting point to establish your tagging conventions, to better understand tagging best practices checkout Cloud Adoption Framework's [Resource naming and tagging decision guide](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/decision-guides/resource-tagging/#resource-tagging-patterns)

Tag Name|Description|Key|Example Value|Required?
--------|-----------|---|-------------|---------|
Project Name|Name of the Project for the infra is created. This is mandatory to create a resource names.|ProjectName|{Project name}|Yes
Application Name|Name of the application, service, or workload the resource is associated with.|ApplicationName|{app name}|Yes
Approver|Name Person responsible for approving costs related to this resource.|Approver|{email}|Yes
Business Unit|Top-level division of your company that owns the subscription or workload the resource belongs to. In smaller organizations, this may represent a single corporate or shared top-level organizational element.|BusinessUnit|FINANCE, MARKETING,{Product Name},CORP,SHARED|Yes
Cost Center|Accounting cost center associated with this resource.|CostCenter|{number}|Yes
Disaster Recovery|Business criticality of this application, workload, or service.|DR|Mission Critical, Critical, Essential|Yes
Environment|Deployment environment of this application, workload, or service.|Environment|Prod, Dev, QA, Stage, Test|Yes
Owner Name|Owner of the application, workload, or service.|Owner|{email}|Yes
Requester Name|User that requested the creation of this application.|Requestor| {email}|Yes
Service Class|Service Level Agreement level of this application, workload, or service.|ServiceClass|Dev, Bronze, Silver, Gold|Yes
Start Date of the project|Date when this application, workload, or service was first deployed.|StartDate|{date}|No
End Date of the Project|Date when this application, workload, or service is planned to be retired.|EndDate|{date}|No

> *__Note:__ This module allows you to manage the above metadata tags directly,as a variable using `variables.tf` or even merge it with tags from `local.tf` All Azure resources which support tagging can be tagged by specifying key-values in argument `tags`.*

#### Directly 
```hcl
module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  #..omitted

  tags = {
    ProjectName  = "Platform-Demo"
    Environment  = "dev"
    Owner        = "user@corp.com"
    BusinessUnit = "CORP"
    CostCenter   = "IT"
    ServiceClass = "Dev"
  }

  #..omitted
}
```
#### Variable in `variable.tf`

`main.tf`
```hcl
module "shared_network" {
  source  = "haflidif/terraform-azurerm-network"
  version = "1.0.0"

  #..omitted

  tags = var.tags

  #..omitted
}
```
`variables.tf`
```hcl
variable "tags" {
  type        = map(string)
  description = "(Optional) Resource tagging"
  default     = {}
}
```

#### With `local` and `variable.tf`
> *__Note:__ Local values can be helpful to avoid repeating the same values or expressions multiple times in a configuration, but if overused they can also make a configuration hard to read by future maintainers by hiding the actual values used, see [Terraform documentation for more information about local blocks](https://www.terraform.io/language/values/locals)*


```hcl
main.tf

  local {
    common_tags = {
      BusinessUnit = "CORP"
      CostCenter   = "IT"
    }
  }

  module "shared_network" {
    source  = "haflidif/terraform-azurerm-network"
    version = "1.0.0"

    #..omitted

    tags = merge(local.common_tags, var.tags)

    #..omitted
  }
```
```hcl
variables.tf
  variable "tags" {
    type        = map(string)
    description = "(Optional) Resource tagging"
    default     = {}
  }
```
---

## Requirements

Name | Version
-----|--------
terraform | >= 0.13
azurerm | >= 2.90.0

### Providers

| Name | Version |
|------|---------
azurerm | >= 2.90.0

---
## Inputs

Name | Description | Type | Default
---- | ----------- | ---- | -------
`resource_group_name` | The name of the resource group in which resources are created | string | `""`
`location`|The location of the resource group in which resources are created| string | `""`
`vnet_name`|The name of the virtual network| string | `""`
`vnet_address_space`|Virtual Network address space to be used |list | `[]`
`dns_servers` | (Optional) List of DNS servers to use for virtual network | list | `[]`
`ddos_protection_plan` | (Optional) If DDoS protection plan should be attatched to the virtual network | object | `[]`
`ddos_protection_plan_id` | (Optional) Provide DDoS Protection Plan Id within the `ddos_protection_plan` object | string | `""`
`enable_ddos_protection_plan` | (Optional) Controls wether DDoS Protection Plan is enabled or disabled | bool | `N/A`
`subnets`| For each subnet, create an object that contain fields| object | `{}`
`subnet_name`| A name of subnets inside virtual network| string | "snet-(Uses `each key` in `subnets` object as deafult)"
`subnet_address_prefix`| A list of subnets address prefixes inside virtual network| `{}`
`delegation`| (Optional) Defines a subnet delegation feature. takes an object as described in the example |object | `{}`
`service_endpoints` | (Optional) Service endpoints for the virtual subnet| object | `{}`
`nsg` | (Optional) Controls if an NSG should be created and attached to the subnet - NSG is __not__ created by default for each subnet | bool | `false`
`nsg_name` | (Optional) Overwrites the use of subnet name minus `snet-` | string | "nsg-(Uses the __subnet name__ *minus `snet-` if present*)"
`nsg_inbound_rule` | (Optional) Define custom NSG inbound rules settings | object | `{}`
`nsg_outbound_rule` | (Optional) Define custom NSG outbound rules settings | object | `{}`
`route_table` | (Optional) Controls if an Route Table should be created and attached to the subnet - RouteTable is __not__ created by default for each subnet | bool | `false`
`route_table_name` | (Optional) Overwrites the use of subnet name minus `snet-` | string | "rt-(Uses the __subnet name__ *minus `snet-` if present*)"
`routes` | (Optional) Define User Defined routes (UDR) for the route table | object | `{}`
`Tags`| A map of tags to add to all resources| map | `{}`

## Outputs

Name | Type | Description
---- | ---- |-----------
`virtual_network_name` | string | The name of the virtual network.
`virtual_network_id` | string | The virtual network id.
`virtual_network_address_space` | list | List of address spaces that are used in the virtual network.
`virtual_network_subnets` | map | Map of subnets created within the module, outputs `id`, `name` and `address_prefixes` in a map based on the subnet key.
`network_security_groups`| map | Map of network security groups (NSG) created by the module, outputs `id` and `name` in a map based on the subnet key
`route_tables` | map | Map of route tables created by the module, outputs `id` and `name` in a map based on the subnet key

### How to reference module outputs
```hcl


```


---
## Authors

Originally created by [Haflidi Fridthjofsson](https://github.com/haflidif)

## Other resources

* [Virtual network documentation (Azure Documentation)](https://docs.microsoft.com/en-us/azure/virtual-network/)
* [Terraform AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest)