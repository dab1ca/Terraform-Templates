terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-01-westeurope" {
  name     = var.resource_group_name
  location = "westeurope"
}

resource "azurerm_service_plan" "rg-01-westeurope" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = azurerm_resource_group.rg-01-westeurope.location
  sku_name            = "F1"
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "rg-01-westeurope" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.rg-01-westeurope.name
  location            = azurerm_resource_group.rg-01-westeurope.location
  service_plan_id     = azurerm_resource_group.rg-01-westeurope.id
  
  site_config {
    always_on         = "false"

    application_stack {
      current_stack     = "dotnet"
      dotnet_version    = "v7.0"
    }
  }
}

resource "azurerm_storage_account" "rg-01-westeurope" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg-01-westeurope.name
  location                 = azurerm_resource_group.rg-01-westeurope.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_server" "rg-01-westeurope" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg-01-westeurope.name
  location                     = azurerm_resource_group.rg-01-westeurope.location
  version                      = "12.0"
  administrator_login          = "tsvetan"
  administrator_login_password = var.sql_server_password
}

resource "azurerm_mssql_firewall_rule" "rg-01-westeurope" {
  name             = "AllowAccess"
  server_id        = azurerm_mssql_server.rg-01-westeurope.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "rg-01-westeurope" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.rg-01-westeurope.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = true
}
