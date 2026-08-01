#=========================================
# Resource Group
#=========================================

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#=========================================
# Virtual Network
#=========================================

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = ["10.0.0.0/16"]
}

#=========================================
# Subnet
#=========================================

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.0.0/24"]
}

#=========================================
# Azure Container Registry
#=========================================

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku           = "Basic"
  admin_enabled = true
}

#=========================================
# Azure Kubernetes Service
#=========================================

resource "azurerm_kubernetes_cluster" "aks" {

  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dns_prefix = "petclinic"

  kubernetes_version = "1.35.6"

  default_node_pool {
    name                        = "system"
    node_count                  = 1
    vm_size                     = "Standard_B2s"
    vnet_subnet_id              = azurerm_subnet.subnet.id
    temporary_name_for_rotation = "tempnode"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  sku_tier = "Free"

  tags = {
    Project = "Spring-PetClinic"
    Managed = "Terraform"
  }
}

#=========================================
# Grant AKS Permission to Pull Images
#=========================================

resource "azurerm_role_assignment" "aks_acr" {

  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"

  principal_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}