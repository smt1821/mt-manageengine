terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.92"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  rg_name  = "mt-poc"
  location = "UK South"
  prefix   = "mt"
}

# -----------------------------
# RESOURCE GROUP
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = local.location
}

# -----------------------------
# VNET + SUBNET
# -----------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${local.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -----------------------------
# PUBLIC IP FOR LOAD BALANCER
# -----------------------------
resource "azurerm_public_ip" "pip" {
  name                = "${local.prefix}-lb-pip"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# -----------------------------
# STANDARD LOAD BALANCER
# -----------------------------
resource "azurerm_lb" "lb" {
  name                = "${local.prefix}-lb"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "bepool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackEndPool"
}

# -----------------------------
# HEALTH PROBE
# -----------------------------
resource "azurerm_lb_probe" "probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "http-probe"
  protocol        = "Tcp"
  port            = 80
}

# -----------------------------
# LB RULE
# -----------------------------
resource "azurerm_lb_rule" "lbrule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.probe.id
}


# -----------------------------
# INBOUND NAT RULES FOR RDP
# -----------------------------
resource "azurerm_lb_nat_rule" "rdp" {
  count                          = 2
  name                           = "rdp-${count.index}"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 50000 + count.index + 1
  backend_port                   = 3389
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
}









# -----------------------------
# NETWORK SECURITY GROUP
# -----------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "${local.prefix}-nsg"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-rdp"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# -----------------------------
# NETWORK INTERFACES (NICs)
# -----------------------------
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "${local.prefix}-nic-${count.index}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# NIC → LB Backend Pool Mapping (New syntax)
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bepool.id
}


# -----------------------------
# NIC → NAT RULE ASSOCIATION
# -----------------------------
resource "azurerm_network_interface_nat_rule_association" "nic_rdp" {
  count                 = 2
  network_interface_id  = azurerm_network_interface.nic[count.index].id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.rdp[count.index].id
}









# Attach NSG
resource "azurerm_network_interface_security_group_association" "assoc" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -----------------------------
# WINDOWS 2016 IIS VMs
# -----------------------------
resource "azurerm_windows_virtual_machine" "vm" {
  count               = 2
  name                = "${local.prefix}-iis-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "mtadmin"
  admin_password      = "ChangeMe123!"

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-datacenter-gensecond"
    version   = "latest"
  }

  os_disk {
    name                 = "${local.prefix}-disk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(<<EOF
<powershell>
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Set-Content -Path "C:\\inetpub\\wwwroot\\index.html" -Value "Hello from IIS $(hostname)"
</powershell>
EOF
  )
}
