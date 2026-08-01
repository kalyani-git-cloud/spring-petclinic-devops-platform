#=========================================
# Resource Group
#=========================================

output "resource_group_name" {
  description = "Azure Resource Group Name"

  value = azurerm_resource_group.rg.name
}

#=========================================
# Virtual Network
#=========================================

output "virtual_network_name" {
  description = "Azure Virtual Network Name"

  value = azurerm_virtual_network.vnet.name
}

#=========================================
# Subnet
#=========================================

output "subnet_name" {
  description = "Subnet Name"

  value = azurerm_subnet.subnet.name
}

#=========================================
# Azure Container Registry
#=========================================

output "acr_name" {
  description = "Azure Container Registry Name"

  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Azure Container Registry Login Server"

  value = azurerm_container_registry.acr.login_server
}

#=========================================
# Azure Kubernetes Service
#=========================================

output "aks_name" {
  description = "AKS Cluster Name"

  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_fqdn" {
  description = "AKS API Server FQDN"

  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "node_resource_group" {
  description = "AKS Managed Resource Group"

  value = azurerm_kubernetes_cluster.aks.node_resource_group
}