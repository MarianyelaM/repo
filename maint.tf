resource "azurerm_resource_group" "RG-marianyela" {
  name     = "RG-marianyela"
  location = "East US 2"
}
resource "azurerm_virtual_network" "VNET" {
  name                = "VNET-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.RG-marianyela.location
  resource_group_name = azurerm_resource_group.RG-marianyela.name
}
resource "azurerm_subnet" "VNET_sub" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.RG-marianyela.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "publicip" {
  name                = "myTFPublicIP"
  location            = azurerm_resource_group.RG-marianyela.location
  resource_group_name = azurerm_resource_group.RG-marianyela.name
  allocation_method   = "Static"
}
resource "azurerm_network_security_group" "nsg" {
  name                = "myTFNSG"
  location            = "westus2"
  resource_group_name = azurerm_resource_group.RG-marianyela.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "allow-http"
    description                = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_interface" "VNET_int" {
  name                = "VNET-nic"
  location            = azurerm_resource_group.RG-marianyela.location
  resource_group_name = azurerm_resource_group.RG-marianyela.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.VNET_sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}
resource "azurerm_windows_virtual_machine" "WINDOWS" {
  name                = "windows-machine"
  resource_group_name = azurerm_resource_group.RG-marianyela.name
  location            = azurerm_resource_group.RG-marianyela.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.VNET_int.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}