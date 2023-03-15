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

resource "azurerm_resource_group" "rg-01-uksouth" {
  name     = var.resource_group_name
  location = var.resource_location
}

resource "azurerm_network_security_group" "rg-01-uksouth" {
  name                = var.network_security_group_name
  location            = azurerm_resource_group.rg-01-uksouth.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "212.27.187.70"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 111
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "212.27.187.70"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAppCommunicationWithDatabase"
    priority                   = 112
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "rg-01-uksouth" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.rg-01-uksouth.location
  resource_group_name = azurerm_resource_group.rg-01-uksouth.name
  address_space       = ["10.21.0.0/24"]
  dns_servers         = []
}

resource "azurerm_subnet" "rg-01-uksouth" {
  name                 = "main-subnet"
  resource_group_name  = azurerm_resource_group.rg-01-uksouth.name
  virtual_network_name = azurerm_virtual_network.rg-01-uksouth.name
  address_prefixes     = ["10.21.0.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "rg-01-uksouth" {
  subnet_id                 = azurerm_subnet.rg-01-uksouth.id
  network_security_group_id = azurerm_network_security_group.rg-01-uksouth.id
}

resource "azurerm_public_ip" "rg-01-uksouth" {
  name                = var.web_vm_piblicip_name
  resource_group_name = azurerm_resource_group.rg-01-uksouth.name
  location            = azurerm_resource_group.rg-01-uksouth.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "rg-01-uksouth" {
  name                = var.web_vm_nic_name
  location            = azurerm_resource_group.rg-01-uksouth.location
  resource_group_name = azurerm_resource_group.rg-01-uksouth.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rg-01-uksouth.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rg-01-uksouth.id
  }
}

resource "azurerm_public_ip" "rg-01-uksouth-db" {
  name                = var.db_vm_piblicip_name
  resource_group_name = azurerm_resource_group.rg-01-uksouth.name
  location            = azurerm_resource_group.rg-01-uksouth.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "rg-01-uksouth-db" {
  name                = var.db_vm_nic_name
  location            = azurerm_resource_group.rg-01-uksouth.location
  resource_group_name = azurerm_resource_group.rg-01-uksouth.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rg-01-uksouth.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rg-01-uksouth-db.id
  }
}

resource "azurerm_linux_virtual_machine" "rg-01-uksouth" {
  name                            = var.web_vm_name
  resource_group_name             = azurerm_resource_group.rg-01-uksouth.name
  location                        = azurerm_resource_group.rg-01-uksouth.location
  size                            = "Standard_D2_v2"
  admin_username                  = "tsvetan"
  admin_password                  = var.server_password
  disable_password_authentication = false
  network_interface_ids           = [
    azurerm_network_interface.rg-01-uksouth.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


resource "azurerm_linux_virtual_machine" "rg-01-uksouth-db" {
  name                            = var.db_vm_name
  resource_group_name             = azurerm_resource_group.rg-01-uksouth.name
  location                        = azurerm_resource_group.rg-01-uksouth.location
  size                            = "Standard_D2_v2"
  admin_username                  = "tsvetan"
  admin_password                  = var.server_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.rg-01-uksouth-db.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}