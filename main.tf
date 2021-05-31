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
  location = azurerm_resource_group.main.location
  name = "vnet-security-group"
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    access = "allow"
    direction = "inbound"
    name = "allow-http"
    priority = 200
    source_address_prefix = "Internet"
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_range = "80"
    description = "Allow HTTP service in vnet"
    protocol = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "http" {
  network_interface_id = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.http.id

  count = var.backend_pool_size
}

resource "azurerm_network_interface" "main" {
  name                = "nic-vm-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  count = var.backend_pool_size
}

resource "azurerm_linux_virtual_machine" "main" {
  resource_group_name   = azurerm_resource_group.main.name
  name                  = "${local.environment}-vm-${count.index}"
  location              = azurerm_resource_group.main.location
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  size               = "Standard_B1ls"
  admin_username        = "endava"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "endava"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(file("./scripts/cloud-config-nginx.yaml"))

  tags = {
    environment = local.environment
  }

  count = var.backend_pool_size
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

resource "azurerm_network_interface_backend_address_pool_association" "lb-backend" {
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app-pool.id
  count = var.backend_pool_size
}

