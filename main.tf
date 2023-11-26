provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "portfolio" {
  name     = "portfolio"
  location = "North Europe"
}

# Virtual Network
resource "azurerm_virtual_network" "portfolio_network" {
  name                = "portfolio_network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name
}

# Subnet
resource "azurerm_subnet" "portfolio_subnet" {
  name                 = "portfolio_subnet"
  resource_group_name  = azurerm_resource_group.portfolio.name
  virtual_network_name = azurerm_virtual_network.portfolio_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Associate the Network Security Group with the Subnet
resource "azurerm_subnet_network_security_group_association" "portfolio_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.portfolio_subnet.id
  network_security_group_id = azurerm_network_security_group.portfolio_nsg.id
}

# Public IP Address
resource "azurerm_public_ip" "portfolio_public_ip" {
  name                = "portfolio_public_ip"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name
  allocation_method   = "Static"
}

# Network Security Group
resource "azurerm_network_security_group" "portfolio_nsg" {
  name                = "portfolio_nsg"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name
}

# Network Interface
resource "azurerm_network_interface" "portfolio_nic" {
  name                = "portfolio_nic"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.portfolio_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.portfolio_public_ip.id
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "portfolio_vm" {
  name                = "portfoliovm"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name
  network_interface_ids = [azurerm_network_interface.portfolio_nic.id]
  size                = "Standard_DS1_v2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "adminuser"
  # Replace with your SSH public key
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/Users/havardvestbo/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Allow HTTP traffic to VM
resource "azurerm_network_security_rule" "http_rule" {
  name                        = "http_rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.portfolio.name
  network_security_group_name = azurerm_network_security_group.portfolio_nsg.name
}

# NSG Rule for allowing SSH access
resource "azurerm_network_security_rule" "ssh_rule" {
  name                        = "ssh_rule"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.portfolio.name
  network_security_group_name = azurerm_network_security_group.portfolio_nsg.name
}
