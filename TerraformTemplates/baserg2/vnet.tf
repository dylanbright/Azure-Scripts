

resource "azurerm_virtual_network" "test" {
  name                = "DCB-BASE-VNT-001"
  location            = "Central US"
  resource_group_name = "DCB-BASE-RG-001"
  address_space       = ["10.100.0.0/16", "10.101.0.0/16"]
}

 