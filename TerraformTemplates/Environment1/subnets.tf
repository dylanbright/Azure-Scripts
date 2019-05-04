resource "azurerm_subnet" "env1Subnet1" {
  name                 = "env1Subnet1"
  resource_group_name  = "DCB-BASE-RG-001"
  virtual_network_name = "DCB-BASE-VNT-001"
  address_prefix       = "10.100.50.0/29"
  }