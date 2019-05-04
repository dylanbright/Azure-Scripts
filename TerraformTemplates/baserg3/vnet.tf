

resource "azurerm_virtual_network" "baserg3" {
  name                = "DCB-BASE-VNT-003"
  location            = "Central US"
  resource_group_name = "DCB-BASE-RG-003"
  address_space       = ["10.150.0.0/16"]
}

 