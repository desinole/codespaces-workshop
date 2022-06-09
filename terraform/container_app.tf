locals {
  location = "eastus"
}

resource "azurerm_resource_group" "rg" {
  name = "desinoleresources"
  location = local.location
}

resource "azurerm_log_analytics_workspace" "laws" {
  name                = "desinolelaw"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azapi_resource" "container_app_environment" {
  name = "desinoleenvironment"  
  location = local.location
  parent_id = azurerm_resource_group.rg.id
  type = "Microsoft.App/managedEnvironments@2022-01-01-preview"
  body = jsonencode({
    properties = {
        appLogsConfiguration = {
            destination = "log-analytics"
            logAnalyticsConfiguration = {
                customerId = azurerm_log_analytics_workspace.laws.workspace_id
                sharedKey = azurerm_log_analytics_workspace.laws.primary_shared_key
            }
        }
    }
  })
}

resource "azapi_resource" "container_app" {
  name = "desinoleapp"  
  location = local.location
  parent_id = azurerm_resource_group.rg.id
  type = "Microsoft.App/containerApps@2022-01-01-preview"
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.container_app_environment.id
      configuration = {
        ingress = {
          targetPort = 80
          external = true
        }
      }
      template = {
        containers = [
          {
            image = "ghcr.io/boxboat-codespaces/desinole-codespaces-workshop:20220609.2"
            name = "desinolecontainer"
          }
        ]
      }
    }
  })
  response_export_values = ["properties.configuration.ingress.fqdn"]
}

output "fqdn" {
  value = jsondecode(azapi_resource.container_app.output).properties.configuration.ingress.fqdn
}