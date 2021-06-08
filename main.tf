locals {
  environment = lower(var.environment)
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.59.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  resource_group_name = azurerm_resource_group.main.name
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
}

resource "azurerm_subnet" "internal" {
  resource_group_name  = azurerm_resource_group.main.name
  name                 = "subnet-internal"
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "http" {
  name = "web-security-group"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name


  security_rule {
    name                       = "allow-http"
    access                     = "allow"
    direction                  = "inbound"
    priority                   = 200
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    description                = "Allow HTTP service in vnet"
    protocol                   = "tcp"
  }
}


resource "azurerm_subnet_network_security_group_association" "http" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.http.id
}

resource "azurerm_linux_virtual_machine_scale_set" "app-vmss" {
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  name = "app-vmss"
  admin_username = var.admin.username
  instances = var.backend_pool_size
  sku = "Standard_B1ls"

  // Image
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  // Storage
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  // Network Interfaces
  network_interface {
    name = "internal-nic"
    primary = true
    network_security_group_id = azurerm_network_security_group.http.id

    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.internal.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.app-pool.id]
    }
  }

  // Auth settings
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin.username
    public_key = var.admin.public_key
  }

  // Provision
  custom_data = base64encode(file("./scripts/cloud-config-nginx.yaml"))

  tags = {
    environment = local.environment
  }
}

// Load Balancer Config
resource "azurerm_public_ip" "main" {
  name                = "${local.environment}-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "main" {
  name                = "${local.environment}-load-balancer"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_rule" "http" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.app-pool.id
  name                           = "PassthroughPort80"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.http.id
}

resource "azurerm_lb_probe" "http" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "http-running-probe"
  port                = 80
  protocol            = "Http"
  request_path        = "/_status"
}

// Address Pool and Associations

resource "azurerm_lb_backend_address_pool" "app-pool" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${local.environment}-app-pool"
}

