
resource "azurerm_network_security_group" "nsg" {
  name                = "DCB-ENV1-NSG-001"
  location            = "Central US"
  resource_group_name = "DCB-ENV1-RG-001"

  security_rule {
    name                       = "AllowDCBHome"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "47.198.79.110"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}