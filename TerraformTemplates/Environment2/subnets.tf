resource "azurerm_subnet" "env2Subnet1" {
  name                 = "env2Subnet1"
  resource_group_name  = "DCB-BASE-RG-001"
  virtual_network_name = "DCB-BASE-VNT-001"
  address_prefix       = "10.100.60.0/29"
  }