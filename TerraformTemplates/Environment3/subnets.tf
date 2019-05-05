resource "azurerm_subnet" "env3Subnet1" {
  name                 = "env3Subnet1"
  resource_group_name  = "DCB-BASE-RG-003"
  virtual_network_name = "DCB-BASE-VNT-003"
  address_prefix       = "10.150.0.64/29"
  }