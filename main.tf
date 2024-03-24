# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id            = "2837fa98-ba70-4d44-a7e7-730ceb335460"
  skip_provider_registration = true
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "osher-rg"
  location = "West Europe"
}

# Create a Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                = "envapplogin"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "apploginubtechtest"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
}

# Create a Container App
resource "azurerm_container_app" "app" {
  name                         = "applogin"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "applogincontainer"
      image  = "${azurerm_container_registry.acr.login_server}/applogin:prod"
      cpu    = 1.0
      memory = "2Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "container-registry-password"
  }
}

# Create an Auto-scale Setting
resource "azurerm_monitor_autoscale_setting" "app_autoscale" {
  name                = "applogin-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_container_app.app.id

  profile {
    name = "default"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "ConcurrentRequests"
        metric_resource_id = azurerm_container_app.app.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 30
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# Assign the AcrPull role to the Container App's managed identity
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.app.identity.0.principal_id
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

output "app_public_ip" {
  value       = azurerm_public_ip.app_public_ip.ip_address
  description = "The public IP address of the Azure Container App."
}

variable "azure_client_secret" {
  description = "The Azure Active Directory Application Secret"
}