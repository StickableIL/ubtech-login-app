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
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "westeurope" # or any location close to Israel
}

# Create an Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "myContainerRegistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
}

# Build and push the Docker image to ACR
resource "null_resource" "build_and_push_image" {
  triggers = {
    docker_file = "${base64sha256(file("./Dockerfile"))}"
  }

  provisioner "local-exec" {
    command = <<EOF
      az acr build --registry ${azurerm_container_registry.acr.login_server} --image myapp:latest .
      az acr import --name ${azurerm_container_registry.acr.name} --source docker.io/library/myapp:latest --image myapp:latest
    EOF
  }
}

# Create an Azure Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                         = "myContainerAppEnv"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  internal_external_ingress    = "External"
  internal_load_balancer_ip    = "10.0.0.6" # example IP
  docker_bridge_cidr           = "172.18.0.1/16"
  internal_private_dns_zone_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/privateDnsZones/privatelink.westeurope.azurecontainerapps.io"
}

# Create an Azure Container App
resource "azurerm_container_app" "app" {
  name                         = "myContainerApp"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  template {
    container {
      image = "${azurerm_container_registry.acr.login_server}/myapp:latest"
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "MY_ENV_VAR"
        value = "myvalue"
      }
    }
    scale {
      min_replicas = 2
      max_replicas = 10
      rules {
        name     = "cpu-scaling"
        type     = "cpu"
        metric   = "cpuPercentage"
        operator = ">"
        value    = 80
        duration = "PT5M"
      }
    }
  }
}

# Create an Azure Database for PostgreSQL
resource "azurerm_postgresql_server" "postgres" {
  name                = "login-postgresql-server"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # ... additional database configuration
}