resource "azurerm_virtual_network_peering" "test1" {
  name                      = "DCB-BASE-VNT-003_to_DCB-BASE-VNT-001"
  resource_group_name       = "DCB-BASE-RG-003"
  virtual_network_name      = "DCB-BASE-VNT-003"
  remote_virtual_network_id = "/subscriptions/11541666-34de-4eaa-84a2-801039426abf/resourceGroups/DCB-BASE-RG-001/providers/Microsoft.Network/virtualNetworks/DCB-BASE-VNT-001"
  allow_virtual_network_access = true
}