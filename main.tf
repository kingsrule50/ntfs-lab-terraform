# =============================================================================
# Lab 1: Azure Infrastructure with Terraform
# Author: Chinedu Asuzu | github.com/kingsrule50
#
# This lab provisions the foundational Azure infrastructure for a
# three-tier Windows lab environment using Terraform.
#
# Resources deployed:
#   - Resource Group
#   - Virtual Network with DNS configured to DC01
#   - Subnet
#   - Network Security Group (RDP access)
#   - Public IPs (Static) for all 3 VMs
#   - Network Interfaces with static private IPs
#   - DC01: Windows Server 2025 (Domain Controller)
#   - FS01: Windows Server 2025 (File Server)
#   - CLIENT01: Windows 11 Pro 24H2 (Domain Client)
#
# Lab 2 (Active Directory) and Lab 3 (NTFS File Server) build on this.
# =============================================================================

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
# DNS servers set to DC01 static IP so all VMs resolve lab.local automatically
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]
  dns_servers         = ["10.0.1.5"]
  depends_on          = [azurerm_resource_group.rg]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP-3389"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.rdp_source
    source_port_range          = "*"
    destination_port_range     = "3389"
    destination_address_prefix = "*"
  }
}

# Public IPs - Static so RDP addresses never change between deployments
resource "azurerm_public_ip" "dc01" {
  name                = "dc01-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "fs01" {
  name                = "fs01-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "client01" {
  name                = "client01-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interfaces with static private IPs
# DC01: 10.0.1.5 (DNS server for the domain)
# FS01: 10.0.1.6
# CLIENT01: 10.0.1.7
resource "azurerm_network_interface" "dc01" {
  name                = "dc01-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.5"
    public_ip_address_id          = azurerm_public_ip.dc01.id
  }
}

resource "azurerm_network_interface" "fs01" {
  name                = "fs01-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.6"
    public_ip_address_id          = azurerm_public_ip.fs01.id
  }
}

resource "azurerm_network_interface" "client01" {
  name                = "client01-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.7"
    public_ip_address_id          = azurerm_public_ip.client01.id
  }
}

# NSG Associations
resource "azurerm_network_interface_security_group_association" "dc01" {
  network_interface_id      = azurerm_network_interface.dc01.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "fs01" {
  network_interface_id      = azurerm_network_interface.fs01.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "client01" {
  network_interface_id      = azurerm_network_interface.client01.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# DC01 - Windows Server 2025 Datacenter
resource "azurerm_windows_virtual_machine" "dc01" {
  name                  = "DC01"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.server_vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.dc01.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface_security_group_association.dc01]
}

# FS01 - Windows Server 2025 Datacenter
resource "azurerm_windows_virtual_machine" "fs01" {
  name                  = "FS01"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.server_vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.fs01.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface_security_group_association.fs01]
}

# CLIENT01 - Windows 11 Pro 24H2
resource "azurerm_windows_virtual_machine" "client01" {
  name                  = "CLIENT01"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.client_vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.client01.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-pro"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface_security_group_association.client01]
}

# Enable RDP on CLIENT01 (disabled by default on Windows 11)
resource "azurerm_virtual_machine_extension" "client01_enable_rdp" {
  name                 = "enable-rdp"
  virtual_machine_id   = azurerm_windows_virtual_machine.client01.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -Command \"Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0; Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'\""
  })

  depends_on = [azurerm_windows_virtual_machine.client01]
}
